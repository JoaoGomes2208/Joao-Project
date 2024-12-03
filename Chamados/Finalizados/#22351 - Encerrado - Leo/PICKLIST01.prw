#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} PPICKLIST
Pick List de Separação de Pedido de Venda por endereçamento
SF2->F2_XPEDLIB
SF2->F2_XPICK
SC5->C5_XPICK

Leonardo - 29.08.2022
Imprimir exceção de transportadora

Leonardo - 20.01.2023
Só imprimir pedido com transportadora

Jonatas - 24 / 04 / 2024
Registrar o usuário que imprimiu o PICK
/*/
//------------------------------------------------------------------------------------------
User Function PPICKLIST()
	Local cPerg 	:= PadR("PPICKLIST",10)
	Private _cFlag 	:= ""
	Private _cAFlag := ""
	Private _nCaixa := 0
	Private _nUnidd := 0
	Private _nTPeso := 0
	Private _nTBruto:= 0
	Private _nVlrTot:= 0
	Private _nCount := 0

	If !Pergunte (PadR(cPerg,10),.T.)
		Return .f.
	EndIf

	If cFilAnt != "03"
		Alert("Esta Mágica só acontece na Filial 03!")
		Return
	Else
		Processa({|| MontaRel() }, "Imprimindo Pick List ...")
	EndIf
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MontaRel
Monta Relatorio

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
Static Function MontaRel()
	Local	cNome		:= ""
//Private	cPath		:= GETMV("RAC_PATHPI",.T.,"C:\Picklists\")
//Private	aDir		:= Directory(cPath,"D")
	Private _lFlag      := .T.
	Private _nLin 		:= 10 	//Controlador da posição das linhas Verticais
	Private _nColIni 	:= 10    //Controlador da posição das linhas horizontais
	Private _nPesoPro	:= 0
	Private _nPesoBPr	:= 0
	Private _nQuant		:= 0
	Private _nEmbalag	:= 0
	Private _nVolume	:= 0
	Private _nPesoLNF	:= 0
	Private _nPesoBNF	:= 0
	Private _nPreco		:= 0
	Private _dEmissao	:= STOD("")
	Private _dDtLibera	:= STOD("")
	Private _cValida	:= STOD("")
	Private _cImpresso  := IIF(MV_PAR02 == 1,"NIMP", IIF(MV_PAR02 == 2, "IMP", "TODOS")) //1 Impresso /2 Nao impresso /3 Ambos
	Private _cTpPick	:= IIF(MV_PAR01 == 1,"PED",IIF(MV_PAR01 == 2,"NF","MKT")) //1 Pedido /2 Nota /3 Mkt
	Private _cPedido    := ""
	Private cQuery 		:= ""
	Private _cDoc		:= ""
	Private _cTipoDoc	:= ""
	Private _cProduto	:= ""
	Private _cDescPro	:= ""
	Private _cUM		:= ""
	Private _cLocal		:= ""
	Private _cEnderec	:= ""
	Private _cLote		:= ""
	Private _cMenssage	:= ""
	Private _cAgenda	:= ""
	Private _cCliente	:= ""
	Private _cLoja		:= ""
	Private _cTransp	:= ""
	Private _cTipoPro	:= ""
	Private _cObserv	:= ""
	Private _nVlrFret	:= ""
	Private _cCNPJ		:= ""
	Private _cPVMatriz	:= ""
	Private _aXEVPC		:= {}
	Private _lXEVPC		:= .F.
	Private _cTipoCli	:= "" //aadd 20220407 jonatas
	Private _cObsLog	:= "" //Add 20240417 L.C.A.
	Private nCount 		:= 0

	//Fontes do Relatório Gráfico
	oFont6  := TFont():New("Tahoma",,9,,.F.,,,,.F.,.F.)
	oFont6n := TFont():New("Tahoma",,9,,.T.,,,,.F.,.F.)
	oFont12n:= TFont():New("Tahoma",,12,,.T.,,,,.F.,.F.)
	oFont24n:= TFont():New("Tahoma",,24,,.T.,,,,.F.,.F.)

	If _cTpPick == 'PED'
		QueryPED()
	ElseIF _cTpPick == 'NF'
		QueryNF()
	ElseIF _cTpPick == 'MKT'//CRIADO EM 02/09/2021
		QueryMKT()
	EndIf

	IncProc("Gerando relatório de Pick-List...")

	cNome  := "Picking-List "+StrTran(DTOC(Date()),"/","_")+"-"+StrTran(time(),":","")
	oPrint := TMSPrinter():New(cNome)
	oPrint:SetLandscape()
	oPrint:SetPaperSize(9)
	oPrint:StartPage()

	While !QRY->(EOF())

		if _cDoc <> QRY->DOCUMENTO
			nCount := 0
		EndIf
		/* Recebe Variaveis - Cabeçalho */
		_cDoc		:= QRY->DOCUMENTO
		_cSerie		:= IIF(_cTpPick=="NF",QRY->SERIE,"")
		_cTipoDoc	:= QRY->TIPO_DOC
		_nVlrFret	:= IIF(_cTpPick=="PED",QRY->VALOR_FRETE,0) //Transferencia que nao tem simulacao de frete
		_dEmissao	:= QRY->EMISSAO
		_nPesoLNF	:= QRY->PESO_LIQUIDO_DOC
		_nPesoBNF	:= QRY->PESO_BRUTO_DOC
		_cMenssage	:= QRY->MENSAGEM
		_cFlag		:= IIF(_cTpPick=="PED",QRY->FLAG,"2") //em caso de nota, nao tem o flag
		_cAgenda	:= IIF(_cTpPick=="PED",QRY->AGENDAMENTO,"2") // em caso de nota, nao considera agendamento
		_cCliente	:= QRY->CLIENTE
		_cLoja		:= QRY->LOJA
		_cTransp	:= QRY->TRANSPORTADORA
		_nVolume	:= QRY->VOLUME
		_cObserv	:= IIF(_cTpPick=="PED",QRY->OBSERVACAO,"") //Em caso de Nota nao tem observacao pedido
		_dDtLibera 	:= Posicione ("SC9",1,(xFilial("SC9")+QRY->DOCUMENTO),"C9_DATALIB")
		_cTipoCli 	:= QRY->TIPOCLI
		_cObsLog 	:= Iif(_cTpPick == 'NF', ' ', QRY->OBSLOG)
		AADD(_aXEVPC, {QRY->VPC, QRY->DOCUMENTO})

		//Controle de Impressão do Cabeçalho do Pedido da Matriz
		//If _cTpPick=="PED"
		//	_cPVMatriz	:= QRY->PVORIGEM
		//Else
		//	SD2->(DbSetOrder(1))
		//		IF SD2->(DbSeek(xFilial("SD2")+_cDoc+_cSerie))
		//		_cPVMatriz := Posicione ("SC5",1,('01'+SD2->D2_PEDIDO),"C5_XNUMPED")
		//	EndIf
		//EndIf

		// Verifica se é beneficiamento
		If _cTipoDoc == 'B'
			cAlias := 'SA2'
		Else
			cAlias := 'SA1'
		Endif

		//Monta Condição para Pegar SA1 OU SA2
		cPref:= Right(cAlias,2)
		Posicione(cAlias,1,xFilial(cAlias)+_cCliente+_cLoja,cPref+"_COD")

		//Se For Cliente, Passa o Flag
		If cAlias == 'SA1' //Alteração
			cAlias += '->'
			_cAFlag := &(cAlias+cPref+"_XFLAG")
		Else
			cAlias += '->'
		Endif
		_cCNPJ := AllTrim(&(cAlias+cPref+"_CGC")) //Não tirar dessa posição

		//Valida se a quantidade de itens é a mesma entre SC6 e SDC
		_lRet := valida_itens(_cDoc)
		If !_lRet
			if _cDoc == QRY->DOCUMENTO .and. nCount == 0
				nCount := nCount + 1
				Alert("Quantidade do pedido "+_cDoc+" está diferente do empenho SDC por endereço. Não é possível prosseguir.")
			Else
				nCount := nCount + 1
			EndIf
			QRY->(DBSKIP())
			loop
		EndIf

		//Se entra em pagina nova pedido - Começa com True
		If _lFlag
			_nLin := 30
			Cabec() // Chama Cabeçalho
			CabecItem() // Chama Cabeçalho Item
			_cPedido:= QRY->DOCUMENTO
			//Grava que o Pick Já Foi Impresso
			If _cTpPick == "PED"
				DbSelectArea("SC5")
				DbSetOrder(1)
				If DbSeek( xFilial("SC5") + _cPedido)
					Reclock("SC5", .F.)
					SC5->C5_XPICK:= 'S'
					SC5->C5_XUSRPIC	:= AllTrim(UsrRetMail(__cUserId)) //ADD JPAIVA 20240425
					SC5->(MsUnlock())
				EndIf
			ElseIf _cTpPick == "NF"
				DbSelectArea("SF2")
				DbSetOrder(1)
				If DbSeek( xFilial("SF2") + _cPedido + _cSerie) // NF + SERIE
					Reclock("SF2", .F.)
					SF2->F2_XPICK:= 'S'
					SF2->(MsUnlock())
				EndIf
			EndIf
		EndIf

		//Verifica se no laço do While, é o mesmo pedido
		If _cDoc <> _cPedido
			Total()
			_nCaixa := 0
			_nUnidd := 0
			_nTPeso := 0
			_nTBruto:= 0
			_nVlrTot:= 0
			_nCount := 0
			Fim()
			oPrint:EndPage()//Fecha a página
			oPrint:StartPage()//Inicia nova página
			_nLin := 30
			Cabec()//Chamada da função que imprime o cabeçalho do Relatório
			CabecItem()//Chamada da Função que imprime o cabeçalho dos Itens
			Body()//Chamada da função que imprime o item
			_cPedido:= QRY->DOCUMENTO

			If _cTpPick == "PED"
				DbSelectArea("SC5")
				DbSetOrder(1)
				If DbSeek( xFilial("SC5") + _cPedido)
					Reclock("SC5", .F.)
					SC5->C5_XPICK:= 'S'
					SC5->C5_XUSRPIC	:= AllTrim(UsrRetMail(__cUserId)) //ADD JPAIVA 20240425
					SC5->(MsUnlock())
				EndIf
			ElseIf _cTpPick == "NF"
				DbSelectArea("SF2")
				DbSetOrder(1)
				If DbSeek( xFilial("SF2") + _cPedido + _cSerie) // NF + SERIE
					Reclock("SF2", .F.)
					SF2->F2_XPICK:= 'S'
					SF2->(MsUnlock())
				EndIf
			EndIf
		Else
			If _nLin <= 1450
				Body()//Chamada da função que imprime o item
				_lFlag := .F.
			Else
				oPrint:EndPage()//Fecha a página
				oPrint:StartPage()//Inicia nova página
				_nLin := 30
				//_nCount++ COMENTADO JONTAS 03/11/2022
				Cabec()//Chamada da função que imprime o cabeçalho do Relatório
				CabecItem()//Chamada da Função que imprime o cabeçalho dos Itens
				Body()//Chamada da função que imprime o item
			EndIf
		EndIf
		//	_nLin += 30
		QRY->(DBSKIP())
	EndDo
	Total()
	Fim()
	oPrint:EndPage() //Fecha a página
	oPrint:Preview()
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} IMPRIMECABECALHO
Monta Relatorio - cabecalho

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
Static Function Cabec()
	DBSelectArea("SM0")
	SM0->(dbSetOrder(1))

	//conta pagina
	_nCount++
	_cFolha := cValToChar(_nCount)
	_nLin += 30
	oPrint:Line(_nLin,_nColIni,_nLin,_nColIni+3300)
	_nLin += 60
	oPrint:Say(_nLin,_nColIni+2985,"Folha..........: "+_cFolha ,oFont6,1400)
	oPrint:Say(_nLin,_nColIni+5,"SIGA/PPICKLIST/v.P12",oFont6,1400)
	oPrint:Say(_nLin,_nColIni+1600,"PICK - LIST",oFont6n,1400)
	oPrint:Say(_nLin,_nColIni+1800,IIF(QRY->XPICK == "S"," RE-IMPRESSAO",""),oFont6n,1400)
	_nLin += 30
	oPrint:Say(_nLin,_nColIni+5,"Hora:"+CVALTOCHAR(Time()),oFont6,1400)
	oPrint:Say(_nLin,_nColIni+2985,"Emissão:"+CVALTOCHAR(Date()),oFont6,1400)
	_nLin += 70
	oPrint:Line(_nLin,_nColIni,_nLin,_nColIni+3300)
	_nLin += 30
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} IMPRIMECABECALHOITENS
Monta Relatorio - cabecalho ITENS

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
Static Function CabecItem()
	_nLin += 20
	oPrint:Say(_nLin, _nColIni+30, "Pedido: "+ _cDoc, oFont12n,1400)
	_nLin += 65
	oPrint:Say(_nLin, _nColIni+30, "Cliente: "+ Substr(AllTrim(&(cAlias+cPref+"_NOME")) + " " + Transform(_cCNPJ, "@R 99.999.999/9999-99"),1,80) , oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1450,"Município: "+ AllTrim(&(cAlias+cPref+"_MUN")) + "-" + AllTrim(&(cAlias+cPref+"_EST")), oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2300,"Data da Liberação: "+dtoc(_dDtLibera), oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2800,"Data da Emissão: "+dtoc(stod(_dEmissao)),oFont6,1440)

	_nLin += 65
	//Identifica se teve agendamento
	If _cAgenda = '1'
		oPrint:Say(_nLin, _nColIni+30, "Agendamento: SIM " , oFont6,1400)
	Else
		oPrint:Say(_nLin, _nColIni+30, "Agendamento: NÃO " , oFont6,1400)
	EndIf
	oPrint:Say(_nLin, _nColIni+1450,  IIf( _cTpPick =="PED", "Consumidor Final - DIFAL: " + iif(_cTipoCli=="F","SIM","NÃO") , "") , oFont6,1400) //ADD 20220407 JONATAS

	_nLin += 65
	If len(_cMenssage) > 75 //Add L.C.A. 20240418
		oPrint:Say(_nLin, _nColIni+30, "Mensagem para Nota: "+AllTrim(Substr(_cMenssage,1,75)), oFont6,1400) //para quebrar linha
		oPrint:Say(_nLin, _nColIni+1450, IIf( _cTpPick =="PED", "Mensagem do Pedido: "+AllTrim(_cObserv) , "") , oFont6,1400)
		_nLin += 30
		oPrint:Say(_nLin, _nColIni+30, AllTrim(Substr(_cMenssage,75,100)), oFont6,1400) //para quebrar linha
		If len(_cMenssage) > 175
			_nLin += 30
			oPrint:Say(_nLin, _nColIni+30, AllTrim(Substr(_cMenssage,175,100)), oFont6,1400)
		EndIf
	Else
		oPrint:Say(_nLin, _nColIni+30, "Mensagem para Nota: "+AllTrim(_cMenssage), oFont6,1400)
		oPrint:Say(_nLin, _nColIni+1450, IIf( _cTpPick =="PED", "Mensagem do Pedido: "+AllTrim(_cObserv) , "") , oFont6,1400)
	EndIf

	If !Empty(AllTrim(_cObsLog))
		_nLin += 65
		oPrint:Say(_nLin, _nColIni+30, "Aviso para logística: "+AllTrim(_cObsLog), oFont6,1400) //Add L.C.A 20240417
	EndIf

	_nLin += 65
	IF left(cAlias,3) == "SA1" //Alteração
		oPrint:Say(_nLin, _nColIni+30, "Transportadora: "+AllTrim(_cTransp) +;
			Iif(!Empty(AllTrim(&(cAlias+cPref+"_XEXTRAN"))) , "|| Exceto transporadora(s): "+ AllTrim(&(cAlias+cPref+"_XEXTRAN")), " "), oFont6, 1400)
	Else
		oPrint:Say(_nLin, _nColIni+30, "Transportadora: "+AllTrim(_cTransp),oFont6, 1400)
	EndIf

	//oPrint:Say(_nLin, _nColIni+2300, IIf( _cTpPick =="PED", "Frete Simulado R$ " + cValToChar(_nVlrFret), "") , oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2800, "Total Volume: ", oFont6,1400)
	_nLin+= 50
	oPrint:Line(_nLin,_nColIni,_nLin,_nColIni+3300)
	_nLin+= 50

	//Realiza a impressão do cabeçalho do Pedido Original
	//If !Empty(_cPVMatriz)
	//	Cabec03(_cPVMatriz)
	//EndIf

	oPrint:Say(_nLin, _nColIni+30, 	 "Código", 			oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+200,  "Desc. Material", 	oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+1000, "Grupo", 			oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+1120, "UM",	 			oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+1200, "Endereço",	 	oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+1370, "Lote", 			oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+1800, "Validade", 		oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+2000, "Quantidade",	 	oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+2300, "Separação", 		oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+2600, "P. Líquido", 		oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+2800, "P. Bruto", 		oFont6n,1400)
	oPrint:Say(_nLin, _nColIni+3100, "Valor", 			oFont6n,1400)
	_nLin += 40
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} IMPRIMEITENS
Monta Relatorio - ITENS

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
Static Function Body()
	_cProduto	:= QRY->PRODUTO
	_cDescPro	:= QRY->DESC_PRODUTO
	_nPesoPro	:= QRY->PESO
	_nPesoBPr	:= QRY->PESO_BRUTO
	_cUM		:= QRY->MEDIDA
	_nQuant		:= QRY->QUANTIDADE
	_cLocal		:= QRY->ARMAZEM
	_cEnderec	:= QRY->ENDERECO
	_cLote		:= QRY->LOTE
	_nEmbalag	:= QRY->EMBALAGEM
	_cTipoPro	:= QRY->TIPO_PRODUTO
	_nPreco		:= IIF(_cTpPick=="PED",QRY->PRECO,Posicione("SD2",3,xFilial("SD2")+_cDoc+_cSerie+_cCliente+_cLoja+_cProduto,"D2_PRCVEN"))
	_cValida	:= DTOC(  Posicione("SB8",5, XFILIAL("SB8") + _cProduto + _cLote, "B8_DTVALID")  )
	_nVol		:= 0 //ZERA EM CADA CHAMADA
	_nResult 	:= 0 //ZERA EM CADA CHAMADA

	oPrint:Say(_nLin, _nColIni+30,   _cProduto, 			oFont6,1400)
	oPrint:Say(_nLin, _nColIni+200,  _cDescPro, 			oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1000, _cTipoPro, 			oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1120, _cUM, 					oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1200, _cEnderec, 			oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1370, _cLote, 				oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1800, _cValida, oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2000, Transform(_nQuant, "@E 999,999,999.99"), oFont6,1400)
	_nVol:= (Int(_nQuant/_nEmbalag)) * _nEmbalag
	_nResult:= _nQuant - _nVol
	oPrint:Say(_nLin, _nColIni+2200, Transform(Noround(_nQuant/_nEmbalag,0), "@E 999,999,999.99")+" Cx "+ AllTrim(Transform(_nResult, "@E 999,999,999.99")) +" Und", oFont6,1400) //Libre
	oPrint:Say(_nLin, _nColIni+2600, Transform(_nPesoPro*_nQuant, "@E 999,999,999.99"), oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2780, Transform(_nPesoBPr*_nQuant,"@E 999,999,999.99"), oFont6,1400)
	oPrint:Say(_nLin, _nColIni+3050, Transform(_nPreco*_nQuant,"@E 999,999,999.99"), oFont6,1400)
	_nLin += 35

	//Acumulador do Documento
	_nCaixa 	+= 	Noround(_nQuant/_nEmbalag,0)
	_nUnidd 	+= _nResult
	_nTPeso 	+= _nPesoPro * _nQuant
	_nTBruto 	+= _nPesoBPr * _nQuant
	_nVlrTot 	+= _nPreco * _nQuant
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} IMPRIMETOTAL
Monta Relatorio -TOTAL

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
Static Function Total()
	Local nX
	_nLin += 35 //verificar folha
	If _nTPeso > 0 .OR. _nVlrTot > 0 //se tem algum pESO ou valor no pedido
		oPrint:Line(_nLin,_nColIni,_nLin,_nColIni+3300)
		oPrint:Say(_nLin, _nColIni+45, "TOTAIS", oFont6, 1400)
		oPrint:Say(_nLin, _nColIni+2000, " ", oFont6,1400)
		oPrint:Say(_nLin, _nColIni+2200, Transform(_nCaixa, "@E 999,999,999.99")+" Cx "+AllTrim(Transform(_nUnidd, "@E 999,999,999.99"))+" Und", oFont6,1400) //Libre
		oPrint:Say(_nLin, _nColIni+2600, Transform(_nTPeso, "@E 999,999,999.99"), oFont6,1400)
		oPrint:Say(_nLin, _nColIni+2800, Transform(_nTBruto,"@E 999,999,999.99"), oFont6,1400)
		oPrint:Say(_nLin, _nColIni+3050, Transform(_nVlrTot,"@E 999,999,999.99"), oFont6,1400)
		_nLin += 95
		oPrint:Say(_nLin, _nColIni+30, "Observação:" , oFont6n,1400)
		oPrint:Say(_nLin, _nColIni+1700, "Separador Por:" , oFont6n,1400)
		oPrint:Say(_nLin, _nColIni+2300, "Conferido Por:" , oFont6n,1400)
		oPrint:Line(_nLin+50,_nColIni,_nLin+50,_nColIni+3300)
		_nLin += 95
		oPrint:Say(_nLin, _nColIni+30, "Faturado Por:" , oFont6n,1400)
		oPrint:Say(_nLin, _nColIni+1700, "Nota Fiscal:" , oFont6n,1400)
		oPrint:Say(_nLin, _nColIni+2300, "Carregamento:" , oFont6n,1400)
		oPrint:Line(_nLin+50,_nColIni,_nLin+50,_nColIni+3300)

		If _cAFlag = "1"
			oPrint:Say(_nLin+100, _nColIni+300, "** CLIENTE PRIORITÁRIO **", oFont24n,1400)
		EndIf
		If _cFlag = "1"
			oPrint:Say(_nLin+100, _nColIni+1700, "** PEDIDO URGENTE **", oFont24n,1400)
		EndIf

		if Len(_aXEVPC) > 0
			For nX:= 1 to Len(_aXEVPC)
				if _aXEVPC[nX][1] == 'R' .AND. _aXEVPC[nX][2] == _cPedido
					_lXEVPC := .T.
				endIf
			Next
		endif

		If _lXEVPC == .T.
			oPrint:Say(_nLin+100, _nColIni+1700, "** ATENÇÃO!!! VPC R!!! **", oFont24n,1400)
		EndIf

		aSize(_aXEVPC,0)
		_lXEVPC := .F.
		//_cCodBar := _cPedido
		//_cCodBar += Substr(StrTran(DTOC(Date()),"/",""),1,4)+""+Substr(StrTran(time(),":",""),1,4)
		//MSBAR('CODE128',1.0,5.8,alltrim(_cCodBar),oPrint,.F.,,.T.,0.070,1.2,,,,.F.)
	EndIf
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} IMPRIMEFIM
Monta Relatorio -FIM

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
Static Function Fim()
	oPrint:Line(_nLin+1570,_nColIni,_nLin+1570,_nColIni+3300)
	oPrint:Say(_nLin+1590, _nColIni+30, "Prodiet Nutrição Clínica Ltda", oFont6,1400)
	oPrint:Say(_nLin+1590, _nColIni+1500, "TOTVS S/A - Protheus", oFont6,1400)
	oPrint:Say(_nLin+1590, _nColIni+2910, "- Hora de Término: "+CVALTOCHAR(Time()), oFont6,1400)
	oPrint:Line(_nLin+1570,_nColIni,_nLin+1570,_nColIni+3300)
Return


/*_______________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Função    ¦ Cabec03  ¦ Autor ¦ Alfred Andersen            ¦ Data ¦ 20/11/18 ¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Descrição ¦ Consulta Saldo de Produtos na Matriz e Filial Depósito		   ¦¦¦
¦¦+----------+-----------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
Static Function Cabec03(_cNum)
Local _cDoc3 		:= "" 
Local _cSerie3 		:= "" 
Local _dEmissao3 	:= "" 
Local _cMenssage3 	:= "" 
Local _cAgenda3 	:= "" 
Local _cTransp3 	:= "" 
Local _cObserv3 	:= "" 
Local _cCNPJ3 		:= "" 
Local _cNome 		:= "" 
Local _cMum 		:= "" 
Local _cUf 			:= "" 
Local _nVlrFret3 	:= 0 

	QueryPED3(_cNum)

	While !QRY3->(EOF())
		/* Recebe Variaveis - Cabeçalho */
		_cDoc3		:= QRY3->DOCUMENTO
		_cSerie3	:= QRY3->SERIE
		_nVlrFret3	:= QRY3->VALOR_FRETE //Transferencia que nao tem simulacao de frete
		_dEmissao3	:= QRY3->EMISSAO
		_cMenssage3	:= QRY3->MENSAGEM
		_cAgenda3	:= QRY3->AGENDAMENTO // em caso de nota, nao considera agendamento
		_cTransp3	:= QRY3->TRANSPORTADORA
		_cObserv3	:= QRY3->OBSERVACAO //Em caso de Nota nao tem observacao pedido
		_cTipoCli	:= QRY3->TIPOCLI //ADD 20220407 

		// Verifica se é beneficiamento
		If QRY3->C5_TIPO $ 'BD'
			SA2->(dbSetOrder(1))
			if SA2->(dbSeek(xFilial("SA2")+QRY3->C5_CLIENTE+QRY3->C5_LOJACLI))
				_cCNPJ3 	:= SA2->A2_CGC
				_cNome		:= SA2->A2_NOME
				_cMum		:= SA2->A2_MUN
				_cUf		:= SA2->A2_EST
			Endif
		Else
			_cCNPJ3 	:= QRY3->A1_CGC
			_cNome		:= QRY3->A1_NOME
			_cMum		:= QRY3->A1_MUN
			_cUf		:= QRY3->A1_EST
		Endif
		QRY3->(DBSKIP())
	End

	_nLin += 20
	oPrint:Say(_nLin, _nColIni+30, "Pedido de Venda Matriz: "+ _cDoc3, oFont12n,1400)
	_nLin += 65
	oPrint:Say(_nLin, _nColIni+30, "Cliente: "+ AllTrim(_cNome) + " " + Transform(_cCNPJ3, "@R 99.999.999/9999-99") , oFont6,1400)
	oPrint:Say(_nLin, _nColIni+1450,"Município: "+ AllTrim(_cMum) + "-" + AllTrim(_cUf), oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2300,"Data da Liberação: ", oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2800,"Data da Emissão: "+dtoc(stod(_dEmissao3)),oFont6,1440)
	_nLin += 65

	//Identifica se teve agendamento
	If _cAgenda3 = '1'
		oPrint:Say(_nLin, _nColIni+30, "Agendamento: SIM " , oFont6,1400)
	Else
		oPrint:Say(_nLin, _nColIni+30, "Agendamento: NÃO " , oFont6,1400)
	EndIf
	
	oPrint:Say(_nLin, _nColIni+30,  IIf( _cTpPick =="PED", "Consumidor Final - DIFAL: " + iif(_cTipoCli=="F","SIM","NÃO") , "") , oFont6,1400) //ADD 20220407 JONATAS
	_nLin += 65

	_cMsg := AllTrim(SUBSTR(_cMenssage3,1,200))
	_nPos := RAT(" ",_cMsg)
	_cMsg := SUBSTR(_cMsg,1,_nPos)

	oPrint:Say(_nLin, _nColIni+30, "Mensagem para Nota: "+_cMsg, oFont6,1400)
	_nLin += 65
	If Len(_cMenssage3) > _nPos
		oPrint:Say(_nLin, _nColIni+30,SPACE(30)+AllTrim(SUBSTR(_cMenssage3,_nPos)), oFont6,1400)
		_nLin += 65
	EndIf

	_nLin += 65
	IF cAlias == "SA1"
		oPrint:Say(_nLin, _nColIni+30, "Transportadora: "+AllTrim(_cTransp) +;
		Iif(!Empty(AllTrim(&(cAlias+cPref+"_XEXTRAN"))) , "|| Exceto transporadora(s): "+ AllTrim(&(cAlias+cPref+"_XEXTRAN")), " "), oFont6, 1400)
	Else  
		oPrint:Say(_nLin, _nColIni+30, "Transportadora: "+AllTrim(_cTransp),oFont6, 1400) 
	EndIf  
	oPrint:Say(_nLin, _nColIni+2300, IIf( _cTpPick =="PED", "Frete Simulado R$ " + cValToChar(_nVlrFret3), "") , oFont6,1400)
	oPrint:Say(_nLin, _nColIni+2800, "Total Volume: ", oFont6,1400)
	_nLin+= 50
	oPrint:Line(_nLin,_nColIni,_nLin,_nColIni+3300)
	_nLin+= 50
Return


/*_______________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Função    ¦ QueryPED ¦ Autor ¦ Alfred Andersen            ¦ Data ¦ 20/11/18 ¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Descrição ¦ 																   ¦¦¦
¦¦+----------+-----------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
Static Function QueryPED()
Local lValTran := SuperGetMV("MV_XVALTRA",.F.,.F.)
	cQuery := "SELECT "
	cQuery += "	C6_NUM DOCUMENTO, "
	cQuery += "	C5_TIPO TIPO_DOC, "
	cQuery += "	C6_PRODUTO PRODUTO, "
	cQuery += "	B1_DESC DESC_PRODUTO, "
	cQuery += "	B1_PESO PESO, "
	cQuery += "	B1_PESBRU PESO_BRUTO,"
	cQuery += "	B1_UM MEDIDA,"
	cQuery += "	B1_QE EMBALAGEM, "
	cQuery += " B1_XEVPC VPC, "
	cQuery += "	DC_QUANT QUANTIDADE,"
	cQuery += "	DC_LOCAL ARMAZEM,"
	cQuery += "	DC_LOCALIZ ENDERECO,"
	cQuery += "	DC_LOTECTL LOTE, "
	cQuery += "	C5_EMISSAO EMISSAO, "
	cQuery += "	C5_VOLUME1 VOLUME,"
	cQuery += "	C5_PESOL PESO_LIQUIDO_DOC, "
	cQuery += "	C5_PBRUTO PESO_BRUTO_DOC, "
	cQuery += "	C5_MENNOTA MENSAGEM, "
	cQuery += "	C5_XFLAG FLAG, "
	cQuery += "	C5_XAGEND AGENDAMENTO, "
	cQuery += "	C5_CLIENTE CLIENTE, "
	cQuery += "	C5_LOJACLI LOJA, "
	cQuery += "	ISNULL(A4_NOME,'') AS TRANSPORTADORA,  "
	cQuery += "	B1_TIPO TIPO_PRODUTO, "
	cQuery += "	C6_PRCVEN PRECO, "
	cQuery += "	C5_OBS OBSERVACAO, "
	cQuery += "	C5_XVLRFR VALOR_FRETE, "
	cQuery += "	C5_XPICK XPICK, "
	cQuery += "	C5_TPFRETE TPFRETE, "//ADD JONATAS 20230120
	cQuery += "	C5_TIPOCLI TIPOCLI, " //ADD JONATAS PAIVA 20220407
	//cQuery += "	C5_XNUMPED PVORIGEM "
	cQuery += "	C5_XOBSLOG OBSLOG " //Add Leonardo Canto Aliberte 20240417
	cQuery += "FROM " + RetSQLName("SDC") + " DC (NOLOCK) "
	cQuery += "INNER JOIN " + RetSQLName("SB1") + " B1 (NOLOCK) ON B1_COD = DC_PRODUTO "
	cQuery += "LEFT JOIN "  + RetSQLName("SC6") + " C6 (NOLOCK) ON C6_FILIAL + C6_NUM + C6_ITEM + C6_PRODUTO = DC_FILIAL + DC_PEDIDO + DC_ITEM + DC_PRODUTO "
	cQuery += "LEFT JOIN "  + RetSQLName("SC5") + " C5 (NOLOCK) ON C5_FILIAL + C5_NUM = DC_FILIAL + DC_PEDIDO "
	cQuery += "LEFT JOIN "  + RetSQLName("SA4") + " A4 (NOLOCK) ON A4_COD = C5_TRANSP AND A4.D_E_L_E_T_ = '' "
	cQuery += "WHERE "
	cQuery += "	DC.DC_ORIGEM  = 'SC6' AND "
	cQuery += " DC_PEDIDO BETWEEN '" + ALLTRIM(MV_PAR03) + "' AND '" + ALLTRIM(MV_PAR04) + "' AND "
	cQuery += "	C5_XPEDLIB   <> 'N'   AND "
	if lValTran //se valida ter transportadora preenchida 
		cQuery += "	((C5_TPFRETE = 'S' AND C5_TRANSP = '') OR (C5_TPFRETE <> 'S' AND C5_TRANSP <> '')) AND " //ADD JONATAS 20230120
	EndIf 
	cQuery += "	DC.D_E_L_E_T_ = ''    AND "
	cQuery += "	C6.D_E_L_E_T_ = ''    AND "
	cQuery += "	C5.D_E_L_E_T_ = ''    AND "
	cQuery += "	B1.D_E_L_E_T_ = '' "
	
	If _cImpresso == "IMP"
		cQuery += "	AND C5_XPICK = 'S'  "
	ElseIf _cImpresso == "NIMP"
		cQuery += " AND C5_XPICK = ' '  "

	EndIf
	//cQuery += " ORDER BY C5_NUM "
	cQuery += " ORDER BY DC_PEDIDO "

	If Select('QRY')<>0
		dbSelectArea('QRY')
		dbCloseArea()
	EndIf
	TcQuery cQuery New Alias "QRY"
Return


/*_______________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Função    ¦ QueryMKT ¦ Autor ¦ Alfred Andersen            ¦ Data ¦ 20/11/18 ¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Descrição ¦ 																   ¦¦¦
¦¦+----------+-----------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
Static Function QueryMKT()
	cQuery := "SELECT "
	cQuery += "	C6_NUM DOCUMENTO, "
	cQuery += "	C5_TIPO TIPO_DOC, "
	cQuery += "	C6_PRODUTO PRODUTO, "
	cQuery += "	B1_DESC DESC_PRODUTO, "
	cQuery += "	B1_PESO PESO, "
	cQuery += "	B1_PESBRU PESO_BRUTO,"
	cQuery += "	B1_UM MEDIDA,"
	cQuery += "	B1_QE EMBALAGEM, "
	cQuery += " B1_XEVPC VPC, "
	cQuery += "	C6_QTDVEN QUANTIDADE,"
	cQuery += "	C6_LOCAL ARMAZEM,"
	cQuery += "	'' ENDERECO,"
	cQuery += "	'' LOTE, "
	cQuery += "	C5_EMISSAO EMISSAO, "
	cQuery += "	C5_VOLUME1 VOLUME,"
	cQuery += "	C5_PESOL PESO_LIQUIDO_DOC, "
	cQuery += "	C5_PBRUTO PESO_BRUTO_DOC, "
	cQuery += "	C5_MENNOTA MENSAGEM, "
	cQuery += "	C5_XFLAG FLAG, "
	cQuery += "	C5_XAGEND AGENDAMENTO, "
	cQuery += "	C5_CLIENTE CLIENTE, "
	cQuery += "	C5_LOJACLI LOJA, "
	cQuery += "	A4_NOME TRANSPORTADORA, "
	cQuery += "	B1_TIPO TIPO_PRODUTO, "
	cQuery += "	C6_PRCVEN PRECO, "
	cQuery += "	C5_OBS OBSERVACAO, "
	cQuery += "	C5_XVLRFR VALOR_FRETE, "
	cQuery += "	C5_XPICK XPICK, "
	cQuery += "	C5_XOBSLOG OBSLOG " //Add Leonardo Canto Aliberte 20240417
	cQuery += "FROM " + RetSQLName("SC6") + " C6 (NOLOCK) "
	cQuery += "INNER JOIN " + RetSQLName("SC5") + " C5 (NOLOCK) ON C5_FILIAL + C5_NUM = C6_FILIAL + C6_NUM "
	cQuery += "INNER JOIN " + RetSQLName("SB1") + " B1 (NOLOCK) ON B1_COD = C6_PRODUTO "
	cQuery += "LEFT JOIN "  + RetSQLName("SA4") + " A4 (NOLOCK) ON A4_COD = C5_TRANSP AND A4.D_E_L_E_T_ = '' "
	cQuery += "WHERE "
	cQuery += "	C6_PRODUTO    = '002775' AND "
	cQuery += "	C5_XPEDLIB   <> 'N' AND "
	cQuery += " C6_NUM BETWEEN '" + ALLTRIM(MV_PAR03) + "' AND '" + ALLTRIM(MV_PAR04) + "' AND "
	cQuery += "	C6.D_E_L_E_T_ = '' AND "
	cQuery += "	C5.D_E_L_E_T_ = '' AND "
	cQuery += "	B1.D_E_L_E_T_ = ''  "
	
	If _cImpresso == "IMP"
		cQuery += "	AND C5_XPICK = 'S'  "
	ElseIf _cImpresso == "NIMP"
		cQuery += " AND C5_XPICK = ' '  "
	EndIf
	//cQuery += " ORDER BY C5_NUM "
	cQuery += " ORDER BY C6_NUM "

	If Select('QRY')<>0
		dbSelectArea('QRY')
		dbCloseArea()
	EndIf
	TcQuery cQuery New Alias "QRY"
Return


/*_______________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Função    ¦ QueryNF  ¦ Autor ¦ Alfred Andersen            ¦ Data ¦ 20/11/18 ¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Descrição ¦ 																   ¦¦¦
¦¦+----------+-----------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
Static Function QueryNF()
	/*-- QUERY PARA NOTA FISCAL COM ENDEREÇO --*/
	cQuery += " SELECT "
	cQuery += " DB_DOC DOCUMENTO, "
	cQuery += " DB_SERIE SERIE, "
	cQuery += " DB_CLIFOR CLIENTE, "
	cQuery += " DB_LOJA LOJA, "
	cQuery += " DB_PRODUTO PRODUTO, "
	cQuery += " B1_DESC DESC_PRODUTO, "
	cQuery += " DB_QUANT QUANTIDADE, "
	cQuery += " B1_PESO PESO,  "
	cQuery += " B1_PESBRU PESO_BRUTO, "
	cQuery += " B1_UM MEDIDA, "
	cQuery += " B1_QE EMBALAGEM, "
	cQuery += " B1_XEVPC VPC, "
	cQuery += " DB_LOCAL ARMAZEM, "
	cQuery += " DB_LOCALIZ ENDERECO, "
	cQuery += " DB_LOTECTL LOTE, "
	cQuery += " B1_TIPO TIPO_PRODUTO, "
	cQuery += " F2_EMISSAO EMISSAO, "
	cQuery += " F2_VOLUME1 VOLUME, "
	cQuery += " F2_PLIQUI PESO_LIQUIDO_DOC, "
	cQuery += " F2_PBRUTO PESO_BRUTO_DOC, "
	cQuery += " F2_MENNOTA MENSAGEM, "
	cQuery += " A4_NOME TRANSPORTADORA, "
	cQuery += " F2_TIPO TIPO_DOC, "
	cQuery += " F2_XPICK XPICK, "
	cQuery += " F2_TIPOCLI TIPOCLI "
	cQuery += " FROM " + RetSQLName("SDB") + " DB (NOLOCK) "
	cQuery += " INNER JOIN " + RetSQLName("SB1") + " B1 (NOLOCK) ON  B1_COD = DB_PRODUTO "
	cQuery += " LEFT JOIN "  + RetSQLName("SF2") + " F2 (NOLOCK) ON  F2_FILIAL + F2_DOC + F2_SERIE + F2_CLIENTE + F2_LOJA =   DB_FILIAL + DB_DOC + DB_SERIE + DB_CLIFOR + DB_LOJA "
	cQuery += " LEFT JOIN "  + RetSQLName("SA4") + " A4 (NOLOCK) ON  F2_TRANSP = A4_COD AND A4.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE "
	cQuery += " DB_DOC BETWEEN '" + ALLTRIM(MV_PAR05) + "' AND '" + ALLTRIM(MV_PAR06) + "' AND "
	cQuery += " DB_ORIGEM IN ('SD2','SC6') AND "
	cQuery += " DB_ATUEST     = 'S' AND "
	cQuery += " DB_ESTORNO    = '' AND "
	cQuery += " DB.D_E_L_E_T_ = '' AND "
	cQuery += " F2.D_E_L_E_T_ = '' AND "
	cQuery += " B1.D_E_L_E_T_ = '' "

	If _cImpresso == "IMP"
		cQuery += " AND F2_XPICK = 'S'  "
	ElseIf _cImpresso == "NIMP"
		cQuery += " AND F2_XPICK = ' '  "
	EndIf

	cQuery += " ORDER BY DB_DOC

	If Select('QRY')<>0
		dbSelectArea('QRY')
		dbCloseArea()
	EndIf

	TcQuery cQuery New Alias "QRY"
Return


/*_______________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Função    ¦ QueryPED3¦ Autor ¦ Alfred Andersen            ¦ Data ¦ 20/11/18 ¦¦¦
¦¦+----------+----------+-------+----------------------------+------+----------+¦¦
¦¦¦Descrição ¦ 																   ¦¦¦
¦¦+----------+-----------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
Static Function QueryPED3(_cNum)
	cQuery := "SELECT "
	cQuery += " C5_NUM DOCUMENTO, C5_EMISSAO EMISSAO, C5_MENNOTA MENSAGEM, C5_XAGEND AGENDAMENTO, A4_NOME TRANSPORTADORA, C5_OBS OBSERVACAO, C5_XVLRFR VALOR_FRETE, A1_NOME, A1_CGC, A1_MUN, A1_EST, C5_SERIE SERIE "
	cQuery += ", C5_TIPO, C5_CLIENTE, C5_LOJACLI  "
	cQuery += " FROM " + RetSQLName("SC5") + " SC5 (NOLOCK) "
	cQuery += "LEFT JOIN " + RetSQLName("SA1") + " SA1 (NOLOCK) ON A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI AND SA1.D_E_L_E_T_ = ' ' "
	cQuery += "LEFT JOIN " + RetSQLName("SA4") + " SA4 (NOLOCK) ON A4_COD = C5_TRANSP  AND SA4.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE C5_FILIAL = '01' "
	cQuery += "   AND C5_NUM    = '" + _cNum + "'
	cQuery += "   AND SC5.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY C5_NUM "

	If Select('QRY3')<>0
		dbSelectArea('QRY3')
		dbCloseArea()
	EndIf

	TcQuery cQuery New Alias "QRY3"
	//Memowrite("c:\temp\QueryPED3.txt",cQuery)
Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} valida_itens
Valida quantidade de itens do empenho SDC X SC6

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
@param 	   Numero do Pedido
@Return    Lógico
/*/
//------------------------------------------------------------------------------------------
Static Function valida_itens(_cDoc) 
Local lRet   := .T. 
Local aArea  := getArea() 
Local cQryDC := "" 
Local cQryC6 := "" 
Local nDc	 := 0 
Local nC6	 := 0 

	cQryDC += " SELECT SUM(DC_QUANT) AS QUANTDC " 
	cQryDC += " FROM "+RetSqlName("SDC")+" SDC (NOLOCK) " 
	cQryDC += " WHERE DC_FILIAL = '"+ xFilial("SDC") + "' " 
	cQryDC += " AND DC_PEDIDO = '"+_cDoc+"' AND DC_ORIGEM = 'SC6' " 
	cQryDC += " AND D_E_L_E_T_ = '' " 

	If Select('QRDC')<>0 
		dbSelectArea('QRDC')   
		dbCloseArea() 
	EndIf 

	TcQuery cQryDC New Alias "QRDC" 

	nDC := QRDC->QUANTDC 

	cQryC6 += " SELECT SUM(C6_QTDVEN) AS QUANTC6 " 
	cQryC6 += " FROM "+RetSqlName("SC6")+" SC6 (NOLOCK), "+RetSqlName("SF4")+" SF4 (NOLOCK) " 
	cQryC6 += " WHERE C6_FILIAL  = F4_FILIAL " 
	cQryC6 += "   AND C6_TES     = F4_CODIGO " 
	cQryC6 += "   AND C6_FILIAL  = '" + xFilial("SC6") + "' " 
	cQryC6 += "   AND C6_NUM     = '"+_cDoc+"' " 
	cQryC6 += "   AND C6_PRODUTO NOT IN ('002775') " 
	cQryC6 += "   AND F4_ESTOQUE    != 'N' " 
	cQryC6 += "   AND SC6.D_E_L_E_T_ = '' and SF4.D_E_L_E_T_ = '' " 

	If Select('QRC6')<>0 
		dbSelectArea('QRC6')   
		dbCloseArea() 
	EndIf 

	TcQuery cQryC6 New Alias "QRC6" 
	nC6 := QRC6->QUANTC6 

	//verificar se tem quantidades diferentes
	IF nDc <> nC6 
		lRet := .F. 
	EndIf 

	RestArea(aArea) 
Return lRet 
