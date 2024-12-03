#Include 'TOTVS.ch'
#Include 'RestFul.CH'
#INCLUDE "TOPCONN.CH"


/*/{Protheus.doc} xWSFRECON
    Post de CTEs entregues na fatura enviada pelo webhook da FreteFy. Insere o doc de entrada e aglutina no financeiro.
    @type wsmethod
    @author  Jonatas Paiva e Giulliano Pinheiro
    @since   05/08/2023
    @version 1.0
*/

WSRESTFUL xWSFRECON DESCRIPTION "Serviço POST - Receber Conhecimentos de Frete "

WSDATA PASS As String

WSMETHOD POST DESCRIPTION "Gravação dos dados de conhecimento e fatura de frete "   WSSYNTAX "/api/v1/xWSFRECON" PATH "/api/v1/xWSFRECON"

END WSRESTFUL


/*/{Protheus.doc} POST
    Método para gravar peso e volume após a separação do pedido
    @type wsmethod
    @author  Jonatas Paiva e Giulliano Pinheiro
    @since   05/08/2023
    @history 26/07/2023, Giulliano Pinheiro, modificações no recebimento do json.
    @history 04/04/2024, Giulliano Pinheiro, criado função getCC() para alterar o centro de custo quando F2_XTIPO2 = '14' (Ecommerce) para atender o fluxo contabil da Tray.
    @version 1.0
    @link https://fretefy.docs.apiary.io/#/reference/eventos Evento: fatura.liberada
    @obs Parametro MV_XPWSCON ativa ou desativa webhook
/*/
WSMETHOD POST WSRECEIVE nullparam WSSERVICE xWSFRECON

	Local cConteudo     := self:getContent()
	Local oJson         := JsonObject():New()
	Local cJson         := ''
	Local nX, nY, nLoop, nDO, nItens
	Local aErpTran      := {}
	Local aCliente      := {}
	Local aCab          := {}
	Local aFatAglu      := {}
	Local aItens        := {}
	Local aIntegra      := {}
	Local aAtuTabInt    := {}
	Local aAtuTabMot    := {}
	Local aDocOri       := {}
	Local aChvNFe       := {}
	Local lRetEx103     := .F.
	Local lExit         := .F.
	Local lFatClosed    := .F.
	Local lTitAglu      := .F.
	Local _lAtivo       := SUPERGETMV("MV_XPWSCON",.F.,.F.)
	Local nICMSValor, nICMSAliq, nICMSBase, nValCTE, nSomaCTE, ncount, nValFat, nValFatDif, nIntegrou, nQtdDocs, nValCTEDiv
	Local cRet, cChkFil, cNF, cDtEmissao, cTES, cNumFatur, cSeriefat, cCentCust, cRetEX290, cTRansp, cDiaVcto, cDtVecto, cCondPag, cChvNF
	PRIVATE cToEmail    := GetNewPar("MV_XWSCEMA","")
	PRIVATE cToLog      := GetNewPar("MV_XWSCLOG","")
	PRIVATE cToFin      := GetNewPar("MV_XWSCFIN","")
	PRIVATE cMotivo     := ""
	PRIVATE lCondPag    := .F.  //Se resultado de calcVecto(cDiaVcto) for NAO ENCONTRADO, atribuir condição de pagamento 005 10 dias e lCondPag será True para enviar email ao financeiro avisando sobre ocorrencia.

	cRet := cChkFil := cNF := cDtEmissao := cTES := cNumFatur := cSeriefat := cCentCust := cRetEX290 := cTRansp := cDiaVcto := cDtVecto := cCondPag := cChvNF := ''
	nICMSValor := nICMSAliq := nICMSBase := nvalCTE := nSomaCTE := ncount := nValFat := nValFatDif := nIntegrou := nQtdDocs := nValCTEDiv := 0

	Self:SetContentType("application/json")

	//Se parametro Estiver .F. para o programa
	if _lAtivo == .F.
		self:SetResponse("Status Code: 200",)
		Return .T.
	endif

	// Parse do conteudo da requisicao.
	cError := oJson:fromJson(cConteudo)

	// Valida erros no parse.
	if !Empty(cError)
		SetRestFault(400, cError)
		return .F.
	endif

	cRet := "Webhook Recebido"

	//Envia json por email durante os testes. TODO remover isso aqui depois
	cJson := oJson:ToJson()
	logEmail('JSON por email xWSFRECON', cJson, .T., cToEmail)

	//Numero da Fatura
	cNumFatur := oJson['data']['numero']
	//Valor da Fatura
	nValFat := oJson['data']['valorTotal']
	//Qtd docs na fatura
	nQtdDocs := len(oJson['data']['documentos'])

	//Converter a data de vencimento para formato Date
	cDtVecto := left(oJson['data']['dhVencimento'], 10)
	dDtVecto := ctod(Substr(cDtVecto,9,2)+"/"+Substr(cDtVecto,6,2)+"/"+Substr(cDtVecto,1,4))

	//Diferença da database para dia do vencimento para calcular a condição de pagamento na aglutinação da fatura.
	cDiaVcto := cValtochar(dDtVecto - dDatabase)

	//Loop no json para capturar os ctes e inserir na tabela de integração
	for nLoop := 1 to len(oJson['data']['documentos'])

		//Checar filial com cnpj
		cNF := padL(ojson['data']['documentos'][nLoop]['numero'],TamSX3('F1_DOC')[01],'0')
		cChkFil := ChkFilial(ojson['data']['documentos'][nLoop]['tomador']['documento'])
		cSeriefat := padL(ojson['data']['documentos'][nLoop]['serie'],TamSX3('F1_SERIE')[01],'0')
		//Valor total do cte
		nValCTE := 0
		nValCTE := ojson['data']['documentos'][nLoop]['valor']

		//Transportadora para tabela integra
		aErpTran := {}
		aErpTran := chkTransp(oJson['data']['documentos'][nLoop]['emitente']['documento'])
		if len(aErpTran) = 0
			cTRansp := ''
		else
			cTRansp := aErpTran[1]
		endif

		//Verifica se a fatura já foi inserida na tabela de integração.
		if chkFatDb(cChkFil, cNumFatur, cNF)
			//Verifica se a fatura já foi integrada (Status True) na tabela de integração.
			if chkFatTF(cChkFil, cNumFatur, cNF)
				nIntegrou += 1
			else
				//verifica se o cte já foi inserido na SD1 e altera status integração para verdadeiro. (criado para tratar casos de falha de comunicação durante a integração do webhook)
				if existeSD1(cChkFil, cNF, cSeriefat, cNumFatur)
					nIntegrou += 1
				endif
			endif
		else
			//Insere fatura na tabela de integração
			aadd(aIntegra, {cChkFil,; //ZZ3_FILIAL
			cNumFatur,; //ZZ3_NUMFAT
			ojson['data']['valorTotal'],; //ZZ3_VALFAT
			cNF,; //ZZ3_NUMCTE
			nValCTE,; //ZZ3_VALCTE
			cTRansp,; //ZZ3_TRANSP
			.F.,; //ZZ3_INTEGR
			DDATABASE,; //ZZ3_DTINTE
			'',; //ZZ3_TITAGL
			'',; //ZZ3_MOTIVO
			cJson}) //ZZ3_JSON
			//Adiciona na tabela de integração
			tabFreteFy(aIntegra[len(aIntegra)])
		endif

		//Verifica se titulo do CTE já foi inserido manualmente e está baixado
		lFatClosed := fatClosed(cChkFil, cNF, cSeriefat, nValCTE, cNumFatur)
		if lFatClosed
			motFalInt(cChkFil,cNumFatur,cNF,"Titulo ja foi baixado")
		endif

	next

	//Se a quantidade de ctes integrados for igual a quantidade de ctes no doc, possui fatura aglutinada e existe fatura em aberto para o CTE (incluido manualmente) sai do programa.
	lTitAglu := fatExiste(cChkFil, cNumFatur, cNF)
	if (nIntegrou == nQtdDocs) .AND. (lTitAglu == .T.)
		self:SetResponse(cRet)
		Return .T.
	endif

	//Criar os arrays e executar execauto MATA103
	for nX := 1 to len(oJson['data']['documentos'])

		cMotivo := ""

		//Checar filial com cnpj
		cNF := padL(ojson['data']['documentos'][nX]['numero'],TamSX3('F1_DOC')[01],'0')
		cChkFil := ChkFilial(ojson['data']['documentos'][nX]['tomador']['documento'])
		If cChkFil == ''
			SetRestFault(400,"Filial nao encontrada para o documento: "+cNF+". Operacao cancelada.")
			lExit := .T.
			cMotivo := "Filial nao encontrada"
			aadd(aAtuTabMot, {cChkFil, cNumFatur, cNF, cMotivo})
			loop
		else
			cFilAnt := cChkFil
		endif

		//Tratamento para quando os impostos possuem valor "null"
		IIF(valType(ojson['data']['documentos'][nX]['imposto']['icms']['valor']) == 'U', nICMSValor := 0, nICMSValor :=  val(ojson['data']['documentos'][nX]['imposto']['icms']['valor']))
		IIF(valType(ojson['data']['documentos'][nX]['imposto']['icms']['aliquota']) == 'U', nICMSAliq := 0, nICMSAliq := val(ojson['data']['documentos'][nX]['imposto']['icms']['aliquota']))
		IIF(valType(ojson['data']['documentos'][nX]['imposto']['icms']['base']) == 'U', nICMSBase := 0, nICMSBase := val(ojson['data']['documentos'][nX]['imposto']['icms']['base']))

		cSeriefat := padL(ojson['data']['documentos'][nX]['serie'],TamSX3('F1_SERIE')[01],'0')

		//Checar transportadora dos itens.
		aErpTran := {}
		aErpTran := chkTransp(oJson['data']['documentos'][nX]['emitente']['documento'])
		if len(aErpTran) = 0
			cMotivo := " Transportadora não cadastrada no Protheus."
			logEmail("Checa Transportadora", "Fatura: "+cNumFatur+" CTE: "+cNF+" Filial " +cChkFil+ " Transportadora não cadastrada no Protheus.", .T., cToLog)
			aadd(aAtuTabMot, {cChkFil, cNumFatur, cNF, cMotivo})
			lExit := .T.
			loop
		endIf

		//Checar cliente no sistema.
		aCliente := chkCliente(ojson['data']['documentos'][nX]['destinatario']['documento'])
		if len(aCliente) = 0
			cMotivo := "Cliente nao cadastrado no Protheus."
			logEmail("Checa Cliente", "Fatura: "+cNumFatur+" CTE: "+cNF+" Filial " +cChkFil+ " Cliente nao cadastrado no Protheus.", .T., cToLog)
			aadd(aAtuTabMot, {cChkFil, cNumFatur, cNF, cMotivo})
			lExit := .T.
			loop
		endIf

		//Captura os documentos de origem
		aDocOri := {}
		aChvNFe := {}
		if valType(oJson['data']['documentos'][nX]['documentos']) != "U"
			for nDO := 1 to len(oJson['data']['documentos'][nX]['documentos'])
				cNumDocOri := padL(oJson['data']['documentos'][nX]['documentos'][nDO]['numero'],TamSX3('D1_DOC')[01],'0')
				cChvNF := oJson['data']['documentos'][nX]['documentos'][nDO]['chave']
				aadd(aDocOri, cNumDocOri)
				aadd(aChvNFe, cChvNF)
			next
		else
			aadd(aDocOri, padL('',TamSX3('D1_DOC')[01],''))
			aadd(aChvNFe, padL('',TamSX3('F1_CHVNFE')[01],''))
		endif
		//Converter a data de emissão para o formato Date
		cDtEmissao := left(oJson['data']['documentos'][nX]['dhEmissao'], 10)
		dDtEmissao := ctod(Substr(cDtEmissao,9,2)+"/"+Substr(cDtEmissao,6,2)+"/"+Substr(cDtEmissao,1,4))

		//Valor total do cte
		nValCTE := 0
		nValCTE := ojson['data']['documentos'][nX]['valor']

		aCab := {}

		aadd(aCab, cChkFil) //F1_FILIAL
		aadd(aCab, cNF) //F1_DOC
		aadd(aCab, cSeriefat) //F1_SERIE
		aadd(aCab, aErpTran[1]) //F1_FORNECE
		aadd(aCab, aErpTran[2]) //F1_LOJA
		aadd(aCab, dDtEmissao) //F1_EMISSAO
		aadd(aCab, ojson['data']['documentos'][nX]['emitente']['uF']) //F1_EST
		aadd(aCab, ojson['data']['documentos'][nX]['chave']) //F1_CHVNFE
		aadd(aCab, nValCTE) // F1_VALMERC ou F1_VALBRUT
		aadd(aCab, nICMSBase)//F1_BASEICM
		aadd(aCab, nICMSValor)//F1_VALICM

		//Adiciona o cabeçalho no array para aglutinação de titulos
		aadd(aFatAglu, aCab)

		aItens := {}

		cTES := getTES(cChkFil, nICMSValor)

		//Dividir o valor pela qtd de docs de origem
		nValCTEDiv := nValCTE / len(aDocOri)

		for nItens := 1 to len(aDocOri)

			//Verifica se CC deve ser mudado em função do F2_XTIPO2 = '14' (Ecommerce)
			cCentCust := ''
			cCentCust := getCC(cChkFil, aChvNFe[nItens])

			aadd(aItens, {cChkFil,; //D1_FILIAL
			cTES,;//D1_TES
			cSeriefat,; //D1_SERIE
			nICMSAliq,;//D1_PICM
			nValCTEDiv,;//D1_VALUNIT
			nValCTEDiv,;//D1_VALTOTAL
			nICMSValor,;//D1_VALICM
			nICMSBase,;//D1_BASEICM
			cCentCust,;//D1_CC
			aErpTran[1],; //D1_FORNECE
			aErpTran[2],; //D1_LOJA
			dDtEmissao,; //D1_EMISSAO
			aDocOri[nItens]}) //D1_NFORI
		next

		//execauto MATA103
		//Verificar se a nf da fatura já foi integrada antes de tentar o execauto
		if chkFatTF(cChkFil, cNumFatur, cNF)
			//Verifica se a fatura já tem um numero de aglutinação.
			if !(fatExiste(cChkFil, cNumFatur, cNF))
				nValFatDif += nValCTE
			endif
			loop
		else
			lRetEx103 := exMATA103(aCab, aItens)
		endif

		if lRetEx103
			//alimenta o array para posteriormente atualizar a tabela de integração com o que foi efetivado
			aadd(aAtuTabInt, {cChkFil, cNumFatur, cNF})
			//Soma o valor do cte para comparar com o valor da fatura.
			nValFatDif += nValCTE
		else
			aadd(aAtuTabMot, {cChkFil, cNumFatur, cNF, cMotivo})
		endif
	next

	//Atualiza a tabela de integração de acordo com o que foi efetivado.
	if len(aAtuTabInt) > 0
		for nY := 1 to len(aAtuTabInt)
			statsInteg(aAtuTabInt[nY][1], aAtuTabInt[nY][2], aAtuTabInt[nY][3])
			motFalInt(aAtuTabInt[nY][1], aAtuTabInt[nY][2], aAtuTabInt[nY][3], "")
		next
	endif

	//Checa por fretes que não foram integrados
	if len(aAtuTabMot) > 0
		for nY := 1 to len(aAtuTabMot)
			motFalInt(aAtuTabMot[nY][1], aAtuTabMot[nY][2], aAtuTabMot[nY][3],aAtuTabMot[nY][4])
		next
	endif

	//Se deu exit, finaliza o programa
	if lExit
		self:SetResponse(cRet)
		Return .T.
	endif

	//Se integrou todos os CTES da fatura, aglutina
	if nValFatDif == nValFat
		//Calcula condição de pagamento
		cCondPag := calcVecto(cDiaVcto)
		//execauto eXFINA290
		cRetEX290 := eXFINA290(aFatAglu, aErpTran, cNumFatur, cCondPag)
		if cRetEX290 != ''
			//Atualizar a tabela de integração
			integAglu(cRetEX290, cChkFil, cNumFatur)
			if !lCondPag
				logEmail("Fatura: "+cNumFatur,"Fatura: "+cNumFatur+" integrada com o titulo aglutinado de numero: "+cRetEX290, .T., cToFin)
			endif
		endif
	else
		logEmail("Fatura: "+cNumFatur,"Fatura: "+cNumFatur+" nao foi integrada, verifique os CTEs no monitor de integracao.", .T., cToFin)
	endif

	self:SetResponse(cRet)

Return .T.


/*/{Protheus.doc} ChkFilial
    Recebe o parametro cCnpj e verifica se a filial existe. Caso não exista, cancela toda a operação para não aglutinar
    meia fatura.
    @type Function
    @author user
    @since 31/07/2023
    @param cCnpj, character, filial no doccob.
    @param cNF, character, numero do documento de entrada nf.
    @return character, cFil, Retorna o numero da filial do doccob caso exista no sistema, '' caso não exista.
/*/
Static Function ChkFilial(cCnpj, cNF)

	Local aArea := FWGetArea()
	Local aSM0Data := {}
	Local nPosFil := 0
	Local cFil := ''

	aSM0Data := FwLoadSM0()
	nPosFil  := Ascan(aSM0Data,{|x| x[18] == cCnpj})

	if nPosFil != 0
		cFil := aSM0Data[nPosFil][2]
	endif

	FWRestArea(aArea)

Return cFil

/*/{Protheus.doc} chkTransp
    Recebe o CNPJ da transporadora vindo do Doccob e devolve o codigo da transportadora no Protheus.
    @type Function
    @author Giulliano Pinheiro
    @since 28/07/2023
    @param cCNPJTrans, character, CNPJ da transportadora.
    @return character, aCodTrans, Codigo da transportadora no Protheus.
/*/
Static Function chkTransp(cCNPJTrans)

	Local aArea := FWGetArea()
	Local aAreaSA2 := SA2->(FWGetArea())
	Local cQryTransp := GetNextAlias()
	Local nCount := 0
	Local aCodTrans := {}

	BEGINSQL Alias cQryTransp
        SELECT
        A2_COD,
        A2_LOJA,
        A2_CGC
        FROM %table:SA2% (NOLOCK) AS SA2
        WHERE A2_CGC = %exp:cCNPJTrans%
        AND A2_MSBLQL <> '1'
        AND SA2.%notdel%
	ENDSQL

	(cQryTransp)->(DBGOTOP())
	while !(cQryTransp)->(EOF())
		//aadd(aCodTrans, alltrim((cQryTransp)->A2_COD))
		aadd(aCodTrans, (cQryTransp)->A2_COD)
		aadd(aCodTrans, alltrim((cQryTransp)->A2_LOJA))
		nCount += 1
		(cQryTransp)->(dbSkip())
	enddo

	if nCount > 1
		aCodTrans := {}
	endif

	FWRestArea(aAreaSA2)
	FWRestArea(aArea)

Return (aCodTrans)


/*/{Protheus.doc} chkCliente
    Recebe o CNPJ do cliente vindo do Doccob e devolve o codigo da cliente no Protheus.
    @type Function
    @author Giulliano Pinheiro
    @since 28/07/2023
    @param cCNPJCli, character, CNPJ do cliente.
    @return array, aCodCli, Codigo do cliente no Protheus.
/*/
Static Function chkCliente(cCNPJCli)

	Local aArea := FWGetArea()
	Local aAreaSA1 := SA1->(FWGetArea())
	Local cQryCli := GetNextAlias()
	Local aCodCli := {}
	//Local nCount := 0

	BEGINSQL Alias cQryCli
        SELECT
        A1_COD,
        A1_LOJA,
        A1_CGC
        FROM %table:SA1% (NOLOCK) AS SA1
        WHERE A1_CGC = %exp:cCNPJCli%
        AND SA1.%notdel%
	ENDSQL

	(cQryCli)->(DBGOTOP())
	while !(cQryCli)->(EOF())
		aadd(aCodCli, alltrim((cQryCli)->A1_COD))
		aadd(aCodCli, alltrim((cQryCli)->A1_LOJA))
		//nCount += 1
		(cQryCli)->(dbSkip())
	enddo

    /*if nCount > 1
        aCodCli := {}
    endif*/

    FWRestArea(aAreaSA1)
    FWRestArea(aArea)
    
Return (aCodCli)


/*/{Protheus.doc} getTES
    Recebe a filial e ICMS no parametro e busca a TES correta de acordo com filial e ICMS.
    @type Function
    @author Giulliano Pinheiro
    @since 01/08/2023
    @param cChkFil, character, filial
    @param nICMS, numeric, Valor do ICMS
    @return character, cTES, TES correta de acordo com filial e ICMS.
/*/
Static Function getTES(cChkFil, nICMS)
    
    Local aArea := FWGetArea()
    Local cTES := ''

    if cChkFil == '01'
        cTES := IIF(nICMS = 0,'019','027')
    elseif cChkFil == '03'
        cTES := IIF(nICMS = 0,'006','005')
    elseif cChkFil == '05'
        cTES := IIF(nICMS = 0,'006','005')
    endif

    FWRestArea(aArea)

Return cTES


/*/{Protheus.doc} exMATA103
    Execauto MATA103
    @type Function
    @author Giulliano Pinheiro
    @since 28/07/2023
    @param aCab, array, cabecalho do cte
    @param aItens, array, itens do cte
    @return logical, lRet, Retorna True se o execauto executar com sucesso.
/*/
Static Function exMATA103(aCab, aItens)
    
    Local aCabec := {}
    Local aItem := {}
    Local aItensD1 := {}
    Local lRet := .F.
    Local nOpc := 3
    Local cNum := ""
    Local nX := 0
    Local nY := 0
    Local cErro := ''

    Private lMsErroAuto := .F.
    Private lAutoErrNoFile := .T.
    //Private lMsHelpAuto := .T.

    cMotivo := ""

    cNum := GetSxeNum("SF1","F1_DOC")
    SF1->(dbSetOrder(1))
    While SF1->(dbSeek(xFilial("SF1")+cNum))
        ConfirmSX8()
        cNum := GetSxeNum("SF1","F1_DOC")
    EndDo

    //Cabeçalho
    aadd(aCabec,{"F1_FILIAL" ,aCab[1] ,NIL})
    aadd(aCabec,{"F1_FORMUL" ,"" ,NIL})
    aadd(aCabec,{"F1_DOC" ,aCab[2] ,NIL})
    aadd(aCabec,{"F1_SERIE" ,aCab[3] ,NIL})
    aadd(aCabec,{"F1_FORNECE" ,aCab[4] ,NIL})
    aadd(aCabec,{"F1_LOJA" ,aCab[5] ,NIL})
    aadd(aCabec,{"F1_COND" ,"007" ,NIL})
    aadd(aCabec,{"F1_EMISSAO" ,aCab[6] ,NIL})
    aadd(aCabec,{"F1_EST" ,aCab[7] ,NIL})
    aadd(aCabec,{"F1_FRETE" , 0 ,Nil})
    aadd(aCabec,{"F1_DESPESA" ,0 ,NIL})
    aadd(aCabec,{"F1_BASEICM" , aCab[10] ,Nil})
    aadd(aCabec,{"F1_VALICM" , aCab[11] ,Nil})
    aadd(aCabec,{"F1_VALMERC" ,aCab[9] ,NIL})
    aadd(aCabec,{"F1_VALBRUT" ,aCab[9] ,NIL})
    aadd(aCabec,{"F1_TIPO" ,"N" ,NIL})
    aadd(aCabec,{"F1_DESCONT" , 0 ,Nil})
    aadd(aCabec,{"F1_DTDIGIT" ,DDATABASE ,NIL})
   //  aadd(aCabec,{"F1_DTDIGIT" ,STOD("20240630") ,NIL})//ADD JPAIVA 20240701 PARA LANÇAMENTO DE FRETE ANTIGO
    aadd(aCabec,{"F1_ESPECIE" ,"CTE" ,NIL})
    aadd(aCabec,{"F1_SEGURO" , 0 ,Nil})
    aadd(aCabec,{"F1_MOEDA" , 1 ,Nil})
    aadd(aCabec,{"F1_STATUS" , "A" ,Nil})
    aadd(aCabec,{"F1_TXMOEDA" , 1 ,Nil})
    aadd(aCabec,{"F1_CHVNFE" ,aCab[8] ,NIL})
    aadd(aCabec,{"F1_XORIGEM", "FRETEFY" ,Nil})

    //Itens
    For nX := 1 To len(aItens)
        aItem := {}
        aadd(aItem,{"D1_FILIAL" ,aItens[nX][1] ,NIL})
        aadd(aItem,{"D1_ITEM" ,StrZero(nX,4) ,NIL})
        aadd(aItem,{"D1_COD" ,"000103" ,NIL})
        aadd(aItem,{"D1_TES" ,aItens[nX][2] ,NIL})
        aadd(aItem,{"D1_UM" ,"UN" ,NIL})
        aadd(aItem,{"D1_QUANT" ,1 ,NIL})
        aadd(aItem,{"D1_VUNIT" ,aItens[nX][5] ,NIL})
        aadd(aItem,{"D1_TOTAL" ,aItens[nX][6] ,NIL})
        aadd(aItem,{"D1_VALICM" ,aItens[nX][7] ,NIL})
        aadd(aItem,{"D1_PICM" ,aItens[nX][4] ,NIL})
        aadd(aItem,{"D1_CONTA" ,"342181" ,NIL})
        aadd(aItem,{"D1_CC" ,aItens[nX][9] ,NIL})
        aadd(aItem,{"D1_FORNECE" ,aItens[nX][10] ,NIL})
        aadd(aItem,{"D1_LOJA" ,aItens[nX][11] ,NIL})
        aadd(aItem,{"D1_EMISSAO" ,aItens[nX][12] ,NIL})
        aadd(aItem,{"D1_DTDIGIT" ,DDATABASE ,NIL})
      //   aadd(aItem,{"D1_DTDIGIT" ,STOD("20240630"),NIL})//ADD JPAIVA 20240701 PARA LANÇAMENTO DE FRETE ANTIGO
        aadd(aItem,{"D1_LOCAL" ,"GG" ,NIL})
        aadd(aItem,{"D1_SERIE" ,aItens[nX][3] ,NIL})
        aadd(aItem,{"D1_TIPO" ,"N" ,NIL})
        //aadd(aItem,{"D1_NFORI" ,"" ,NIL})
        aadd(aItem,{"D1_NFORI" ,aItens[nX][13] ,NIL})
        aadd(aItem,{"D1_ITEMORI" ,StrZero(nX,1) ,NIL})
        aadd(aItem,{"D1_SERIORI" ,"" ,NIL})
        //aadd(aItem,{"D1_SERIORI" ,aItens['?'] ,NIL})
        aadd(aItem,{"D1_BASEICM" ,aItens[nX][8] ,NIL})
        aadd(aItem,{"D1_CLVL" ,"00036" ,NIL})
        //aadd(aItem,{"D1_CLASFIS" ,"000" ,NIL})
        /*aadd(aItem,{"D1_CUSTO" ,aItens['?'] ,NIL})
        aadd(aItem,{"D1_BASIMP5" ,aItens['?'] ,NIL})
        aadd(aItem,{"D1_BASIMP6" ,aItens['?'] ,NIL})
        aadd(aItem,{"D1_VALIMP5" ,aItens['?'] ,NIL})
        aadd(aItem,{"D1_VALIMP6" ,aItens['?'] ,NIL})*/
        aadd(aItem,{"D1_RATEIO" ,"2" ,NIL})

        if(nOpc == 4)//Se for classificação deve informar a variável LINPOS
            aAdd(aItem, {"LINPOS" , "D1_ITEM",  StrZero(nX,4)}) //ou SD1->D1_ITEM  se estiver posicionado.
        endIf

        aAdd(aItensD1,aItem)
    Next nX

    //3-Inclusão / 4-Classificação / 5-Exclusão
    MSExecAuto({|x,y,z,/*k,a,b*/| MATA103(x,y,z/*,,,,k,a,,,b*/)},aCabec,aItensD1,nOpc,/*aParamAux*/,/*aItensRat*/,/*aCodRet*/)

    If !lMsErroAuto
        lRet := .T.
    Else
        //MostraErro()
        aLog := GetAutoGRLog()
        For nY := 1 To Len(aLog)
            If !Empty(cErro)
                cErro += CRLF
            EndIf
            cErro += aLog[nY]
        Next nY
        cMotivo := aLog[1]
        logEmail('Integracao do CTE (exMATA103) ', cErro, .T., cToLog)
    EndIf

Return lRet


/*/{Protheus.doc} eXFINA290
    Execauto FINA290 aglutina titulos.
    @type Function
    @author Giulliano Pinheiro
    @since 01/08/2023
    @param aFatPag, array, array com os dados para criar o titulo aglutinado.
    @param aErpTran, array, array com os dados da transportadora.
    @return character, cRet, Retorna vazio se o execauto não executar com sucesso ou retorna o numero do titulo aglutinado em caso de sucesso.
    @link https://tdn.totvs.com/pages/releaseview.action?pageId=647444836
/*/
Static Function eXFINA290(aFatAglu, aErpTran, cNumFatur, cCondPag)
        
    Local aFatPag := {}
    Local aTits := {}
    Local nTamTit := TamSx3("E2_NUM")[1]
    Local nTamParc := TamSx3("E2_PARCELA")[1]
    Local nTamForn := TamSx3("E2_FORNECE")[1]
    Local nTamLoja := TamSx3("E2_LOJA")[1]
    Local nTamTipo := TamSx3("E2_TIPO")[1]
    //Local nTamFil  := TamSx3("E2_FILIAL")[1]
    Local nX := 0
    Local cRet := ""
    Local nY := 0
    Local cResult := ''
    Local aLog := {}
    Private lMsErroAuto := .F.
    Private lAutoErrNoFile := .T.

    //Verifica se a condição de pagamento recebida da função calcVecto é válida
    if cCondPag == 'NAO ENCONTRADO'
        cCondPag := '005' //10 dias
        lCondPag := .T.
    endif

    //[13] - ARRAY com os titulos da fatura - Geradores (esses títulos devem existir na base)
    for nX := 1 to len(aFatAglu)
        aadd(aTits,;
            {aFatAglu[nX][3],;
            PADR(aFatAglu[nX][2],nTamTit),; //Numero
            PADR(" ",nTamParc),; //Parcela
            PADR("NF",nTamTipo),; //Tipo
            .f.,; //Título localizado na geracao de fatura (lógico). Iniciar com falso.
            PADR(aFatAglu[nX][4],nTamForn),; //Fornecedor
            PADR(aFatAglu[nX][5],nTamLoja)}) //Loja
            //PADR("D MG 01 ",nTamFil); // Filial (utilizada em fatura de títulos de diferentes filiais)
    next    

    aFatPag := {"FT",; //Prefixo
                PADR("FT",nTamTipo),; //Tipo
                PADR(cNumFatur ,nTamTit),; //Numero da Fatura (se o numero estiver em branco obtem pelo FINA290)
                "049",; //Natureza
                (DDATABASE-365),; //Data de
                DDATABASE,; //Data Ate
                PADR(aErpTran[1],nTamForn),; //Fornecedor
                PADR(aErpTran[2],nTamLoja),; //Loja
                PADR(aErpTran[1],nTamForn),; //Fornecedor para geracao
                PADR(aErpTran[2],nTamLoja),; //Loja do fornecedor para geracao
                cCondPag,; //Condicao de pagto
                01,; //Moeda
                aTits,; //ARRAY com os titulos da fatura - Geradores
                0,; //Valor de decrescimo
                0} //Valor de acrescimo
    
    MsExecAuto( { |x,y| FINA290(x,y)}, 3, aFatPag )
    
    If !lMsErroAuto
        cRet := getNumTit(aFatPag)
        if lCondPag
            logEmail("Titulo: "+cRet,"Atencao! Condicao de pagamento nao encontrada para o titulo "+cRet+". Titulo criado com condição de pagamento 005 (10 dias). Numero Fatura: "+cNumFatur, .T., cToFin)
        endif
    Else
        //Captura o log do execauto
        aLog := GetAutoGRLog()
        For nY := 1 To Len(aLog)
            cResult := "Fatura: "+cNumFatur+" "
            If !Empty(cResult)
                cResult += CRLF
            EndIf
            cResult += aLog[nY]
        Next nY
        logEmail('Integracao da fatura (FINA290) ', cResult, .T., cToFin)
    EndIf

Return cRet

/*/{Protheus.doc} logEmail
    Envia logs por email
    @type Function
    @author Giulliano Pinheiro
    @since 03/08/2023
    @param cSubFuncao, character, Subfuncao para o FWLogMsg.
    @param cLogMsg, character, mensagem para o FWLogMsg.
    @param lEnviaEmail, logical, envia email usando u_sendemail?.
    @param cMailTo, character, para qual email enviar.
/*/
Static Function logEmail(cSubFuncao, cLogMsg, lEnviaEmail, cMailTo)

    Local _cTo          := cMailTo
    Local _cAssunto     := 'CTEs FreteFy '+cSubFuncao
    Local cBody         := ""
    Local cHTML         := ""
    
    if lEnviaEmail
        cBody +="<html>"
        cBody +="<body>"
        cBody +="<h4>Ocorrencias na integração dos CTEs do FreteFy: "+cSubFuncao+"</h4>"
        cHTML +="<p>"+cLogMsg+"</p>"
        cBody += cHTML
        cBody +="</body></hmtl>"

        U_SendEMail(,,,,_cTo,_cAssunto,cBody)
    endif

Return

/*/{Protheus.doc} tabFreteFy
    Salva os dados integrados em uma tabela de integração ZZ3. OBS: enviar valores em todas as posições do array.
    @type Function
    @author Giulliano Pinheiro
    @since 03/08/2023
    @param aLogIntegra, array, Array com os dados para adicionar na tabela de integracao.
    @return logical, lRet, Retorno True para sucesso e False para falha.
/*/
Static Function tabFreteFy(aLogIntegra)
    
    Local aArea         := FWGetArea()
    Local aAreaZZ3 := ZZ3->(FWGetArea())
    Local lRet := .F.

    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(2)) //ZZ3_FILIAL+ZZ3_NUMFAT+ZZ3_NUMCTE
    ZZ3->(DbGoTop())
    if !ZZ3->(MSSEEK(aLogIntegra[1]+PADR(aLogIntegra[2],TAMSX3('ZZ3_NUMFAT')[1]," ")+PADR(aLogIntegra[4],TAMSX3('ZZ3_NUMCTE')[1]," ")))
        if Reclock('ZZ3',.T.)
            ZZ3->ZZ3_FILIAL := aLogIntegra[1]
            ZZ3->ZZ3_NUMFAT := aLogIntegra[2]
            ZZ3->ZZ3_VALFAT := aLogIntegra[3]
            ZZ3->ZZ3_NUMCTE := aLogIntegra[4]
            ZZ3->ZZ3_VALCTE := aLogIntegra[5]
            ZZ3->ZZ3_TRANSP := aLogIntegra[6]
            ZZ3->ZZ3_INTEGR := aLogIntegra[7]
            ZZ3->ZZ3_DTINTE := aLogIntegra[8]
            ZZ3->ZZ3_TITAGL := aLogIntegra[9]
            ZZ3->ZZ3_MOTIVO := aLogIntegra[10]
            ZZ3->ZZ3_JSON := aLogIntegra[11]
            ZZ3->(MSUNLOCK())
            lRet := .T.
        endif
    /*else
        if ZZ3->ZZ3_INTEGR != aLogIntegra[7]
            if Reclock('ZZ3',.F.)
                ZZ3->ZZ3_INTEGR := aLogIntegra[7]
                ZZ3->(MSUNLOCK())
                lRet := .T.
            endif
        endif*/
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return

/*/{Protheus.doc} integAglu
    Realiza alteração dos ctes da fatura incluindo o numero do titulo aglutinado na tabela de integração.
    @type Function
    @author Giulliano Pinheiro
    @since 04/08/2023
    @param cRetEX290, character, Numero do titulo aglurinado.
    @param cChkFil, character, Filial.
    @param cNumFatur, character, Numero da fatura.
/*/
Static Function integAglu(cRetEX290, cChkFil, cNumFatur)
    
    Local aArea := FWGetArea()
    Local aAreaZZ3 := ZZ3->(FWGetArea())

    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(1)) //ZZ3_FILIAL+ZZ3_NUMFAT
    ZZ3->(DbGoTop())
    while ! ZZ3->(EOF())
        if ZZ3->ZZ3_FILIAL == cChkFil .AND. ZZ3->ZZ3_NUMFAT == PADR(allTrim(cNumFatur),TAMSX3('ZZ3_NUMFAT')[1]," ")
            if Reclock('ZZ3',.F.)
                ZZ3->ZZ3_TITAGL := cRetEX290
                ZZ3->(MSUNLOCK())
            endif
        endif
        ZZ3->(dbSkip())
    enddo

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return

/*/{Protheus.doc} getNumTit(aFatAglu)
    Gera log não retorna nada para o execauto FINA290, função criada para trazer o numero do titulo que acabou de ser criado.
    @type Function
    @author user
    @since 04/08/2023
    @param aFatAglu, array, array com os dados do titulo lançado.
    @return character, cNumTitAgl, Numero do titulo recem lançado.
/*/
Static Function getNumTit(aFatAglu)

    Local aArea := FWGetArea()
    Local aAreaZZ3 := ZZ3->(FWGetArea())
    Local cQryTit := GetNextAlias()
    Local nCount := 0
    Local cNumTitAgl := ''

    BEGINSQL Alias cQryTit
        SELECT MAX(E2_NUM) AS E2_NUM
        FROM RetSqlName('SE2') (NOLOCK) AS SE2 WHERE SE2.D_E_L_E_T_ <> '*'
        AND E2.E2_PREFIXO = %exp:aFatAglu[1]%
        AND E2.E2_TIPO = %exp:aFatAglu[2]%
        AND E2.E2_NATUREZ = %exp:aFatAglu[4]%
        AND E2.E2_FORNECE = %exp:aFatAglu[7]%
        AND E2.E2_LOJA = %exp:aFatAglu[8]%
        AND E2.E2_EMISSAO = %exp:aFatAglu[6]%
    ENDSQL
    
    (cQryTit)->(DBGOTOP())
    while !(cQryTit)->(EOF())
        cNumTitAgl := allTrim((cQryTit)->E2_NUM)
        nCount += 1
        (cQryTit)->(dbSkip())
    enddo

    if nCount > 1
        cNumTitAgl := ''
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return cNumTitAgl

/*/{Protheus.doc} statsInteg
    Altera o status da integração (ZZ3_INTEGR) para verdadeiro.
    @type Function
    @author Giulliano Pinheiro
    @since 08/08/2023
    @param cFil, character, filial
    @param cNumFatur, character, numero da fatura
    @param cNF, character, numero do cte
/*/
Static Function statsInteg(cFil, cNumFatur, cNF)
    
    Local aArea         := FWGetArea()
    Local aAreaZZ3      := ZZ3->(FWGetArea())
    
    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(2)) //ZZ3_FILIAL+ZZ3_NUMFAT+ZZ3_NUMCTE
    ZZ3->(DbGoTop())
    if ZZ3->(MSSEEK(cFil+PADR(cNumFatur,TAMSX3('ZZ3_NUMFAT')[1]," ")+PADR(cNF,TAMSX3('ZZ3_NUMCTE')[1]," ")))
        if Reclock('ZZ3',.F.)
            ZZ3->ZZ3_INTEGR := .T.
            ZZ3->(MSUNLOCK())
        endif    
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return

/*/{Protheus.doc} chkFatDb
    Verifica se a fatura ja foi inserida na tabela de integração, criado pois o webhook pode ser reenviado várias vezes.
    @type Function
    @author Giulliano Pinheiro
    @since 11/08/2023
    @param cChkFil, character, filial da fatura
    @param cNumFatur, character, numero da fatura
    @param cNF, character, numero do cte
    @return logical, lRet, Retorna .T. caso a fatura já esteja no banco.
/*/
Static Function chkFatDb(cChkFil, cNumFatur, cNF)

    Local aArea         := FWGetArea()
    Local aAreaZZ3      := ZZ3->(FWGetArea())
    Local lRet          := .F.
    
    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(2)) //ZZ3_FILIAL+ZZ3_NUMFAT+ZZ3_NUMCTE
    ZZ3->(DbGoTop())
    if ZZ3->(MSSEEK(cChkFil+PADR(cNumFatur,TAMSX3('ZZ3_NUMFAT')[1]," ")+PADR(cNF,TAMSX3('ZZ3_NUMCTE')[1]," ")))
        lRet := .T.
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return lRet


/*/{Protheus.doc} motFalInt
    Insere o motivo da não integração no campo ZZ3_MOTIVO.
    @type Function
    @author Giulliano Pinheiro
    @since 08/08/2023
    @param cFil, character, filial
    @param cNumFatur, character, numero da fatura
    @param cNF, character, numero do cte
    @param cMotivo, character, motivo para não integrar
/*/
Static Function motFalInt(cFil, cNumFatur, cNF, cMotivo)
    
    Local aArea         := FWGetArea()
    Local aAreaZZ3      := ZZ3->(FWGetArea())
    
    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(2)) //ZZ3_FILIAL+ZZ3_NUMFAT+ZZ3_NUMCTE
    ZZ3->(DbGoTop())
    if ZZ3->(MSSEEK(cFil+PADR(cNumFatur,TAMSX3('ZZ3_NUMFAT')[1]," ")+PADR(cNF,TAMSX3('ZZ3_NUMCTE')[1]," ")))
        if Reclock('ZZ3',.F.)
            ZZ3->ZZ3_MOTIVO := cMotivo
            ZZ3->(MSUNLOCK())
        endif    
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return

/*/{Protheus.doc} chkFatTF
    Verifica se a fatura está integrada (True) ou não (False)
    @type Function
    @author Giulliano Pinheiro
    @since 11/08/2023
    @param cChkFil, character, filial da fatura
    @param cNumFatur, character, numero da fatura
    @param cNF, character, numero do cte
    @return logical, lRet, Retorna .T. caso a fatura já esteja no banco.
/*/
Static Function chkFatTF(cChkFil, cNumFatur, cNF)

    Local aArea         := FWGetArea()
    Local aAreaZZ3      := ZZ3->(FWGetArea())
    Local lRet          := .F.
    
    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(2)) //ZZ3_FILIAL+ZZ3_NUMFAT+ZZ3_NUMCTE
    ZZ3->(DbGoTop())
    if ZZ3->(MSSEEK(cChkFil+PADR(cNumFatur,TAMSX3('ZZ3_NUMFAT')[1]," ")+PADR(cNF,TAMSX3('ZZ3_NUMCTE')[1]," ")))
        IIF(ZZ3->ZZ3_INTEGR == .F., lRet := .F., lRet := .T.)
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)

Return lRet

/*/{Protheus.doc} fatExiste
    Verifica se a fatura aglutinada existe no sistema para esta fatura.
    @type Function
    @author Giulliano Pinheiro
    @since 11/08/2023
    @param cChkFil, character, filial da fatura
    @param cNumFatur, character, numero da fatura
    @param cNF, character, numero do cte
    @return logical, lRet, Retorna .T. caso a fatura já esteja no banco.
/*/
Static Function fatExiste(cChkFil, cNumFatur, cNF)
    Local aArea         := FWGetArea()
    Local aAreaZZ3      := ZZ3->(FWGetArea())
    Local lRet          := .F.
    
    dbSelectArea('ZZ3')
    ZZ3->(DBSETORDER(2)) //ZZ3_FILIAL+ZZ3_NUMFAT+ZZ3_NUMCTE
    ZZ3->(DbGoTop())
    if ZZ3->(MSSEEK(cChkFil+PADR(cNumFatur,TAMSX3('ZZ3_NUMFAT')[1]," ")+PADR(cNF,TAMSX3('ZZ3_NUMCTE')[1]," ")))
        IIF(allTrim(ZZ3->ZZ3_TITAGL) == "", lRet := .F., lRet := .T.)
    endif

    FWRestArea(aAreaZZ3)
    FWRestArea(aArea)
Return lRet

/*/{Protheus.doc} existeSD1
    Verifica se o cte já integrou na SD1 e muda o status na tabela de integração.
    @type Function
    @author Giulliano Pinheiro
    @since 11/08/2023
    @param cChkFil, character, filial da fatura
    @param cNF, character, numero do cte
    @param cSeriefat, character, serie do cte
    @param cNumFatur, character, numero da fatura
    @return logical, lRet, Retorna .T. caso a fatura já esteja no banco.
/*/
Static Function existeSD1(cChkFil, cNF, cSeriefat, cNumFatur)
    Local aArea         := FWGetArea()
    Local aAreaSD1      := SD1->(FWGetArea())
    Local lRet          := .F.
    Local cMotivo       := ""
    
    dbSelectArea('SD1')
    SD1->(DBSETORDER(1)) //D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
    SD1->(DbGoTop())
    if SD1->(MSSEEK(cChkFil+PADR(cNF,TAMSX3('D1_DOC')[1]," ")+PADR(cSeriefat,TAMSX3('D1_SERIE')[1]," ")))
        statsInteg(cChkFil, cNumFatur, cNF)
        motFalInt(cChkFil, cNumFatur, cNF, cMotivo)
        lRet := .T.
    endif

    FWRestArea(aAreaSD1)
    FWRestArea(aArea)
Return lRet


/*/{Protheus.doc} fatClosed
    Verifica se a fatura do CTE já foi baixada e não tenta criar aglutinação. Para casos onde foi lançado e pago manualmente.
    @type Function
    @author Giulliano Pinheiro
    @since 13/10/2023
    @param cChkFil, character, Filial
    @param cNF, character, Numero CTE
    @param cSeriefat, character, Serie do CTE
    @param nValCTE, Numeric, Valor do CTE
    @param cNumFatur, Character, Numero fatura
/*/
Static Function fatClosed(cChkFil, cNF, cSeriefat, nValCTE, cNumFatur)
    
    Local aArea := FWGetArea()
    Local aAreaSE2 := SE2->(FWGetArea())
    Local cQrySE2 := GetNextAlias()
    Local lFatExist := .F.
    Local lRet := .F.

    BEGINSQL Alias cQrySE2
        SELECT
            E2_FILIAL, E2_VALOR, E2_PREFIXO,
            E2_NUM, E2_SALDO, E2_BAIXA
        FROM %table:SE2% (NOLOCK) AS SE2
        WHERE SE2.%notdel%
        AND E2_NUM = %exp:cNF%
        AND E2_PREFIXO = %exp:cSeriefat%
        AND E2_VALOR = %exp:nValCTE%
    ENDSQL

    (cQrySE2)->(DBGOTOP())
    if !(cQrySE2)->(EOF())
        if alltrim((cQrySE2)->E2_BAIXA) <> '' .OR. (cQrySE2)->E2_SALDO = 0
            lFatExist := fatExiste(cChkFil, cNumFatur, cNF)
            if lFatExist
                lRet := .F.
            else
                lRet := .T.
            endif
        endif
    endif

    FWRestArea(aAreaSE2)
    FWRestArea(aArea)

Return lRet

/*/{Protheus.doc} calcVecto
Recebe o vencimento da fatura e calcula usando a condição de pagamento SE4
@type function
@author Giulliano Pinheiro
@since 13/10/2023
@param cDiaVcto, character, Vencimento da fatura
@return character, cNewCond, vencimento calculado, retorna 'NAO ENCONTRADO' caso a query não retorne um valor de codigo de condição de pagamento, é NECESSÁRIO tratar na função eXFINA290()
/*/
Static Function calcVecto(cDiaVcto)

    Local aArea := FWGetArea()
    Local aAreaSE2 := SE2->(FWGetArea())
    Local cQrySE4 := GetNextAlias()
    Local cNewCond := ""

    BEGINSQL Alias cQrySE4
        SELECT 
            E4_CODIGO, E4_COND, E4_DESCRI
        FROM %table:SE4% (NOLOCK) AS SE4 WHERE SE4.%notdel%
        AND LEN(E4_COND) <= 2 
        AND E4_DDD = 'L'
        AND E4_CODIGO IN (
            '004',	'026',	'059',	'098',	'010',
            '030',	'055',	'024',	'025',	'005',
            '027',	'021',	'053',	'034',	'009',
            '057',	'040',	'052',	'022',	'039',
            '017',	'038')
        AND E4_COND = %exp:cDiaVcto%
    ENDSQL

    (cQrySE4)->(DBGOTOP())
    if !(cQrySE4)->(EOF())
        cNewCond := alltrim((cQrySE4)->E4_CODIGO)
    else
        cNewCond = 'NAO ENCONTRADO'
    endif

    FWRestArea(aAreaSE2)
    FWRestArea(aArea)

Return cNewCond

/*/{Protheus.doc} getCC
    função para alterar o centro de custo quando F2_XTIPO2 = '14' (Ecommerce) para atender o fluxo contabil da Tray.
    @type Function
    @author Giulliano Pinheiro
    @since 04/04/2024
    @param _cFilial, character, Numero da nota fiscal de origem.
    @param _cChvNF, character, chave da nota fiscal de origem.
    @return character, cEcoCC, centro de custo do Ecommerce 32
/*/
Static Function getCC(_cFilial, _cChvNF)

    Local aArea := FWGetArea()
    Local aAreaSF2 := SF2->(FWGetArea())
    Local _SF2Qry := GetNextAlias()
    Local cCCOri := ""
    Local cEcoCC := ""

    BEGINSQL Alias _SF2Qry
        SELECT
            F2_XTIPO2,
            F2_FILIAL,
            F2_DOC,
            F2_CHVNFE
        FROM %table:SF2% (NOLOCK) AS SF2
        WHERE SF2.%notdel%
        AND F2_CHVNFE = %exp:_cChvNF%
        AND F2_FILIAL = %exp:_cFilial%
    ENDSQL

    (_SF2Qry)->(DBGOTOP())
    if !(_SF2Qry)->(EOF())
        cCCOri := (_SF2Qry)->(F2_XTIPO2)
    endif
    
    //ALERT(Posicione("SF2",1,xFilial("SF2") + "000079096" + "1  " + "001458" + "01","F2_XTIPO2"))

    if cCCOri == '14'
        cEcoCC := '32'
    else
        //Centro de custo de acordo com filial
        cEcoCC := IIF(_cFilial == '03' .OR. _cFilial == '05', '25', '07')
    endif
    
    FWRestArea(aAreaSF2)
    FWRestArea(aArea)

Return cEcoCC
