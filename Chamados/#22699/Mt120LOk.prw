#INCLUDE 'totvs.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"
#Include "TbiConn.ch"

/*/{Protheus.doc} MT120F
PE Após salvar o pedido de compras: Este PE verifica se existem produtos ALT* no Pedido de compras
e pede para o usuario trocar os ALT através de uma MSDIALOG e então altera tanto a SC quanto o PC através de execauto.
*Produtos ALT são aqueles que estão na tabela SGI, no campo GI_PRODORI
@type function
@author gPinheiro
@since 5/11/2023
/*/
User Function MT120LOK()
//Local aArea      := GetArea()
	Local cFil       := CFILIALENT
	Local cPedido    := CA120NUM
	Local aNovoProd  := {}
//Local aCBkp      := aCols
//Local aHBkp      := aHeader
	Local nPosProd   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_PRODUTO' })
	Local nPosItem   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_ITEM' })
	Local nPosQtde   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_QUANT' })
	Local nPosCCusto := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_CC' })
	Local nPosPreco  := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_PRECO' })
	Local nPosTotal  := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_TOTAL' })
	Local nNumSC     := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_NUMSC' })
	Local nItemSC    := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_ITEMSC' })
	Local _cProduto  := alltrim(aCols[n][nPosProd])
	Local _cTpProd   := Posicione("SB1",1,xFilial("SB1")+_cProduto,"B1_TIPO") //SB1->B1_TIPO //
	Local _cItemAlt  := alltrim(aCols[n][nPosItem])
	Local _nQtde     := aCols[n][nPosQtde]
	Local _nPreco    := aCols[n][nPosPreco]
	Local _nTotal    := aCols[n][nPosTotal]
	Local _cNumSC    := alltrim(aCols[n][nNumSC])
	Local _cItemSC   := alltrim(aCols[n][nItemSC])
	Local _cCCusto   := aCols[n][nPosCCusto]
	Local lValido    := .T.
	Local cTmp
	Local _nLinha    := 0
	Local _cUser     := SuperGETMV("MV_USRNPC",.F.,"")
	Private aLogs    := {}
	Private aDadosPC := {}
//Variaveis da tela
	Private cLbx, oDlg, oLbx, oChk
	Private _lChk    := .F.
	Private lSelect  := .F.
	Private cTitulo  := 'Atenção'
	Public cCodCompr := ''

	If __cUserId $ (_cUser)
		MSGINFO('Usuário sem permissão para incluir/alterar, favor entrar em contato com o administrador.', cTitulo)
        lValido := .F.
	Else
		If !(_cTpProd) $ 'EM|MP|PA' .and. Empty(_cCCusto)
			lValido := .F.
			MsgInfo("Favor informar o centro de custo.","Centro de custo")
			AutoGRLog("Favor informar o centro de custo." + CRLF)
		ElseIf FwIsInCallStack("CN121Encerr")
			_nQtdeSC := Posicione("SC1",1,xFilial("SC1")+_cNumSC+_cItemSC,"C1_QUANT")
			If Empty(_cNumSC)
				_nLinha++
				// Utilizado GrvLog, pois esse fonte não exibe alertas
				GrvLog(cValToChar(_nLinha) +". Não foi vinculado solicitação de compra para o item "+ AllTrim(_cProduto) +"."+ CRLF)
				lValido := .F.
			ElseIf Empty(_cCCusto)
				_nLinha++
				// Utilizado GrvLog, pois esse fonte não exibe alertas
				GrvLog(cValToChar(_nLinha) +". Não foi informado centro de custo."+ CRLF)
				lValido := .F.
			ElseIf _nQtde < _nQtdeSC
				_nLinha++
				// Utilizado GrvLog, pois esse fonte não exibe alertas
				GrvLog(cValToChar(_nLinha) +". Quantidade da solicitação ("+_cNumSC+") não atende a medição."+ CRLF)
				lValido := .F.
			Else
				//Conout("Mt120LOk - Atendeu aos requisitos.")
				FWLogMsg("INFO", /*cTransactionId*/, "Compras", "Mt120LOk", /*cStep*/, /*cMsgId*/, "Atendeu aos requisitos.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf
		EndIf

		If len(aLogs) > 0
			ExibeLog()
		EndIf

		// PE é acionado somente na rotina de Pedido de Compras, na operação altera ou inclui
		if (FWIsInCallStack("MATA121")) .AND. (INCLUI .OR. ALTERA)
			// Procura por alternativos na SGI
			SGI->(DBSETORDER(1))
			if SGI->(MSSEEK(xFilial("SGI")+_cProduto))
				MSGINFO('Produto ALT PAI encontrado '+_cProduto+", Item "+_cItemAlt, cTitulo)
            /*  Se encontrar na SGI, chama a tela de seleção na função GetItemAlt para trocar o produto ALT
                Adiciona novo produto e os demais dados necessarios no array para enviar ao execauto
                aNovoProd{1 Filial, 2 Numero Pedido, 3 Novo Produto, 4 Item Pedido, 5 Numero Solicitação de Compras, 6 Item SC}
            */
				AADD(aNovoProd, {cFil,cPedido,GetItemAlt(alltrim(_cProduto)),alltrim(_cItemAlt),alltrim(_cNumSC), alltrim(_cItemSC)})
				// Se existirem novos produtos no array aNovoProd, executa os Execautos
				if LEN(aNovoProd) > 0
					// 3 = inclusão, 4 = alteração, 5 = exclusão
					IF alltrim(_cNumSC) != ""
						EA_MATA110(aNovoProd, 4)
					Endif

					// Atualizo o acols com o novo produto em tela
					aCols[n][nPosProd]   := aNovoProd[1][3]

					// Executo o trigger na mão para trazer a descrição do produto em tela
					cTmp			    := __ReadVar
					__ReadVar 		    := "M->C7_PRODUTO"
					M->C7_PRODUTO       := aNovoProd[1][3]
					If ExistTrigger("C7_PRODUTO")
						RunTrigger(2,n,Nil,,"C7_PRODUTO")
					Endif
					__ReadVar	:= cTmp

					// Executa as validações para inserir no banco
					aCols[n, GdFieldPos('C7_PRODUTO')] := aNovoProd[1][3]
					A120Produto( aCols[n, GdFieldPos('C7_PRODUTO')])
					A120Trigger("C7_PRODUTO")
					aCols[n, GdFieldPos('C7_QUANT')] := _nQtde
					A120Trigger("C7_QUANT")
					aCols[n, GdFieldPos('C7_PRECO')] := _nPreco
					A120Trigger("C7_PRECO")
					aCols[n, GdFieldPos('C7_TOTAL')] := _nTotal
					A120Trigger("C7_TOTAL")
				Endif
			Endif
		Endif
	EndIf
	//RestArea(aArea)
Return lValido


/*----------+-----------+-------+--------------------+------+----------------+
! Descricao ! Função auxiliar de adição da mensagem de log no array de Logs	 !
! 			! de sucesso e erros da rotina									 !
+---------------------------------------------------------------------------*/
Static Function GrvLog(cLog)
	aAdd(aLogs,cLog)
Return


/*----------+-----------+-------+--------------------+------+----------------+
! Descricao ! Função chamada ao final do processamento para exibição do LOG	 !
! 			! de sucesso e erros da rotina									 !
+---------------------------------------------------------------------------*/
Static Function ExibeLog()
	Local cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local cTexto	:= ''
	Local   cFile     := ""
	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL	
	
	cTexto := LeLog()

	Define Font oFont Name "Courier New" Size 8, 18

	Define MsDialog oDlg Title "Error log (Medição x Pedido de compra x Solicitação de compra)" From 3, 0 to 450, 673 Pixel

	@ 5, 5 Get oMemo Var cTexto Memo Size 330, 200 Of oDlg Pixel
	oMemo:bRClicked := { || AllwaysTrue() }
	oMemo:oFont     := oFont

	Define SButton From 209, 309 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
	Define SButton From 209, 279 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
	MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

	Activate MsDialog oDlg Center
Return


/*----------+-----------+-------+--------------------+------+----------------+
! Descricao ! Função que efetua a leitura do array de LOG do sistema e 	 	 !
! 			! retorna em variável para exibição em tela						 !
+---------------------------------------------------------------------------*/
Static Function LeLog()
	Local nA	:= 0
	Local cRet := ''
	
	For nA := 1 To Len(aLogs)
		cRet += aLogs[nA] + CRLF
	Next nA
Return cRet


/*/{Protheus.doc} GetItemAlt
Checa por itens alternativos, apresenta uma tela para substituição
e retorna o novo item. Os botões esc e sair foram desabilitados para forçar a escolha de um produto substituto.
@type function
@author gPinheiro
@since 5/12/2023
@param cProduto, character, Codigo do produto ALT
@return character, cNovoProd, Item que será salvo no lugar do produto ALT
/*/
Static Function GetItemAlt(cProduto)

    //Local aArea  := GetArea()
    Local cAliasQry := GetNextAlias()
    Local oOk      	:= LoadBitmap(GetResources(), "LBOK")
    Local oNo      	:= LoadBitmap(GetResources(), "LBNO")
    Private cNovoProd := ""

    BEGINSQL Alias cAliasQry
        SELECT
            GI_PRODORI,
            SB12.B1_DESC AS PRODORI_DESC,
            GI_PRODALT,
            SB1.B1_DESC AS PRODALT_DESC
        FROM %table:SGI% (NOLOCK) AS SGI
        INNER JOIN %table:SB1% (NOLOCK) AS SB1
        ON B1_COD = GI_PRODALT
        AND SB1.B1_MSBLQL <> '1'
        AND SB1.%notDel%
        INNER JOIN %table:SB1% (NOLOCK) AS SB12
        ON SB12.B1_COD = GI_PRODORI
        AND SB1.B1_MSBLQL <> '1'
        AND SB12.%notDel%
        WHERE SGI.%notDel%
        AND GI_PRODORI = %Exp:cProduto%
    ENDSQL

    (cAliasQry)->(DBGOTOP())
    while ! (cAliasQry)->(EOF())
        aAdd(aDadosPC,{ .F.,;
                        Alltrim((cAliasQry)->GI_PRODORI),;
                        Alltrim((cAliasQry)->PRODORI_DESC),;
                        Alltrim((cAliasQry)->GI_PRODALT),;
                        Alltrim((cAliasQry)->PRODALT_DESC)})
        (cAliasQry)->(DBSkip())
    enddo

    //Monta a tela para selecionar os produtos alternativos
    Define MSDialog oDlg Title "Alteracao Produto Alternativo"  From 0, 0 To 320, 900 Pixel STYLE DS_MODALFRAME
    
    @ 140,400 Button "&Confirmar" Size 45, 15 Action {lSelec:= .T.,IIF(ChecaMark(aDadosPC),Close(oDlg),NIL),/*Close(oDlg)*/} Pixel OF oDlg
    
    @ 08,08 LISTBOX oLbx VAR cLbx FIELDS HEADER " ","Produto Origem","Nome Prod Origem", "Produto Alternativo","Nome Prod Alternativo" SIZE 437,120 OF oDlg PIXEL ON;
    dblClick(IIF(oLbx:ColPos==1,aDadosPC[oLbx:nAt,1] := !(aDadosPC[oLbx:nAt,1]),NIL),oLbx:Refresh())
    
    oLbx:SetArray( aDadosPC ) 
    oLbx:bLine := {|| {Iif(aDadosPC[oLbx:nAt,1],oOk,oNo),aDadosPC[oLbx:nAt,2], aDadosPC[oLbx:nAt,3], aDadosPC[oLbx:nAt,4], aDadosPC[oLbx:nAt,5]}}
    
    //Não permite fechar a janela com ESC
    oDlg:lEscClose := .F.
    Activate MSDialog oDlg Centered

    //RestArea(aArea)
Return cNovoProd


/*/{Protheus.doc} ChecaMark
Verifica o resultado da seleção, apenas 1 item deve ser selecionado
para retornar .T.
@type function
@author gPinheiro
@since 5/12/2023
@param aDados, array, Recebe o array das seleções da janela
@return logical, lRet, Se mais de um item ou nenhum item for selecionado,
retorna .F., se 1 item for selecionado, retorna .T.
/*/
Static Function ChecaMark(aDados)

    Local nX
    Local nCount := 0
    Local lRet := .F.

    for nX := 1 to len(aDados)
        if aDados[nX][1] = .T.
            nCount ++
            if nCount > 1
                MSGINFO('Selecione apenas 1 item', cTitulo)
                lRet := .F.
                Return lRet
            else
                cNovoProd := aDados[nX][4]
            Endif
        ENDIF
    next
    if nCount != 1
        MSGINFO('Nenhum item selecionado, selecione 1 item.', cTitulo)
        lRet := .F.
        Return lRet 
    Endif
    lRet := .T.
Return lRet


/*/{Protheus.doc} EA_MATA121
Static function responsavel por rodar o execauto do MATA121 no modo alteração
(VER COM O JONATAS A POSSIBILIDADE DE CRIAR UMA USER FUNCTION PARA OS EXECAUTOS E REAPROVEITAR EM FUTUTAS INTEGRAÇÕES)
@type  Function
@author user
@since 15/05/2023
@param aNovoProd, array, array com o novo produto para substuição através do execauto do MATA121.
@param nOpc, Numeric, Numero da operação, 3 = inclusão, 4 = alteração, 5 = exclusão.
@return Logical, lRet, Retorno do sucesso ou falha da operação.
/*/
Static Function EA_MATA121(aNovoProd, nOpc)
    
    //Local aArea  := GetArea()
    Local aCabec	:= {}
    Local aItens	:= {}
    Local aLinha	:= {}
    Local cFil		:= aNovoProd[1][1]
    Local cNumPed	:= aNovoProd[1][2]
    Local cProd     := aNovoProd[1][3]
    Local cItem		:= aNovoProd[1][4]
    PRIVATE lMsErroAuto := .F.

    dbSelectArea("SC7")
    SC7->(DBSETORDER(1))
    If SC7->(MSSEEK(cFil+cNumPed+cItem))

        //Executa a alteração
        aadd(aCabec,{"C7_FILIAL",cFil})
        aadd(aCabec,{"C7_NUM" ,cNumPed})
        aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
        aadd(aCabec,{"C7_FORNECE" ,SC7->C7_FORNECE})
        aadd(aCabec,{"C7_LOJA" ,SC7->C7_LOJA})
        aadd(aCabec,{"C7_COND" ,SC7->C7_COND})
        aadd(aCabec,{"C7_CONTATO" ,SC7->C7_CONTATO})
        aadd(aCabec,{"C7_FILENT" ,SC7->C7_FILENT})

        aadd(aLinha,{"C7_ITEM" ,cItem ,Nil})
        aadd(aLinha,{"C7_PRODUTO" ,cProd,Nil})
        aadd(aLinha,{"C7_QUANT" ,C7_QUANT ,Nil})
        aadd(aLinha,{"C7_PRECO" ,C7_PRECO ,Nil})
        aadd(aLinha,{"C7_TOTAL" ,C7_TOTAL ,Nil})

        aadd(aLinha,{"C7_NUMSC" ,C7_NUMSC ,Nil})
        aadd(aLinha,{"C7_ITEMSC" ,C7_ITEMSC ,Nil})

        aAdd(aLinha,{"LINPOS","C7_ITEM" ,cItem})
        aAdd(aLinha,{"AUTDELETA","N" ,Nil})
        aadd(aItens,aLinha)

        MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabec,aItens,nOpc,.F.)

        If lMsErroAuto
            MostraErro()          
        EndIf
    else
        MSGINFO('Pedido '+cNumPed+' nao encontrado', 'Erro')
    endif
    //RestArea(aArea)
Return


/*/{Protheus.doc} EA_MATA110
Static function responsavel por rodar o execauto do MATA110 no modo alteração
(VER COM O JONATAS A POSSIBILIDADE DE CRIAR UMA USER FUNCTION PARA OS EXECAUTOS E REAPROVEITAR EM FUTUTAS INTEGRAÇÕES)
@type  Function
@author user
@since 15/05/2023
@param aNovoProd, array, array com o novo produto para substuição através do execauto do MATA121.
@param nOpc, Numeric, Numero da operação, 3 = inclusão, 4 = alteração, 5 = exclusão.
@return Logical, lRet, Retorno do sucesso ou falha da operação.
/*/
Static Function EA_MATA110(aNovoProd, nOpc)
    
    //Local aArea  := GetArea()
    Local aCabec	:= {}
    Local aItens	:= {}
    Local aLinha	:= {}
    Local cFil		:= aNovoProd[1][1]
    Local cProd     := aNovoProd[1][3]
    Local _cNumSC    := aNovoProd[1][5]
    Local _cItemSC   := aNovoProd[1][6]
    PRIVATE lMsErroAuto := .F.

    dbSelectArea("SC1")
    SC1->(DBSETORDER(1))
    If SC1->(MSSEEK(cFil+_cNumSC+_cItemSC))

        //Executa a alteração
        aadd(aCabec,{"C1_NUM" ,_cNumSC})
        aadd(aCabec,{"C1_SOLICIT",SC1->C1_SOLICIT})
        aadd(aCabec,{"C1_EMISSAO",SC1->C1_EMISSAO})
        aadd(aCabec,{"C1_UNIDREQ",SC1->C1_UNIDREQ})
        aadd(aCabec,{"C1_CODCOMP",""})

        aadd(aLinha,{"C1_ITEM" ,_cItemSC,Nil})
        aadd(aLinha,{"C1_PRODUTO",cProd,Nil})
        aadd(aLinha,{"C1_QUANT" ,SC1->C1_QUANT ,Nil})
        aadd(aLinha,{"C1_CC", SC1->C1_CC, Nil})
        aadd(aItens,aLinha)

        MSExecAuto({|x,y,z| mata110(x,y,z)},aCabec,aItens,nOpc)

        If lMsErroAuto
            MostraErro()
        EndIf
    else
        MSGINFO('Solicitacao '+_cNumSC+' nao encontrada', 'Erro')
    endif
    //RestArea(aArea)
Return
