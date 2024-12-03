#Include "FileIO.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#Include "TopConn.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} xAtuSD3
@author    Jonatas Paiva
@version   1.00
@since     31/07/2024

//grava no errado
/*/
//------------------------------------------------------------------------------------------
User Function xAtuSD3()
	Local aXEmpFil	:= {"03","01"}
	Local nHandle 	:= 0
	Local cDir 		:= "/anexos/logs/"
	Local cArq 		:= ""
	Local nX		:= 1

	PREPARE ENVIRONMENT EMPRESA aXEmpFil[1] FILIAL aXEmpFil[2] FUNNAME FunName() TABLES "SD3"

	cArq := "xatuSD3"+DTOS(Date())+".txt"
	nHandle := FCreate(cDir+cArq)

//valida abertura do arquivo
	If nHandle == -1
		FWLogMsg("INFO", /*cTransactionId*/, "Sched", "XATUSD3", /*cStep*/, /*cMsgId*/, "Arquivo não pode ser aberto."+ CRLF, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
//posiciona no topo do arquivo		
	FT_FGOTOP()
	FWrite(nHandle,"Inicio da Gravação Log "+Time()+ CRLF)

	DbSelectArea("SD3")
	SD3->(DbSetOrder(8))//FILAIL DOC NUMSEQ
	SD3->(DbGoTop())

	DbSelectArea("SD7")
	SD7->(DbSetOrder(3)) //FILIAL + PRODUTO + NUMSEQ + NUMERO
	SD7->(DbGoTop())

	cQuery:= " SELECT * "
	cQuery+= " FROM "+RetSqlName("SD3")+" SD3 (NOLOCK) "
	cQuery+= " WHERE "
	cQuery+= " 	SD3.D3_XMOTTRA  = '' AND "
	cQuery+= " 	SD3.D3_LOCAL IN ('T1','S3') AND "
	cQuery+= " 	SD3.D3_EMISSAO >= GETDATE()-60 AND "
	cQuery+= " 	SD3.D_E_L_E_T_  = ' ' "

	If (Select ("QRY")<> 0)
		QRY->(DbCloseArea())
	EndIf

	TcQuery cQuery New Alias "QRY"
	nCount:= 0
	Count to nCount
	QRY->(dbGoTop())
	While QRY->(!EOF())
		SD7->(DbGoTop())
		SD3->(DbGoTop())
		IF SD7->(dbSeek(QRY->D3_FILIAL+QRY->D3_COD+QRY->D3_NUMSEQ+QRY->D3_DOC))
			IF SD3->(dbseek(QRY->D3_FILIAL+QRY->D3_DOC+QRY->D3_NUMSEQ))
				IF !Empty(AllTrim(SD7->D7_XMOTRAN))//<-PRD
					FWrite(nHandle,"Motivo "+ QRY->D3_XMOTTRA +" inserido com sucesso: NumSeq->" + QRY->D3_NUMSEQ + CRLF)
					For nX:= 1 to 2 //For para preencher tanto saida quanto entrada
						RecLock("SD3",.F.)
						SD3->D3_XMOTTRA := SD7->D7_XMOTRAN//<-PRD
						SD3->(MsUnlock())
						SD3->(DBSKIP())
					Next
					nX := 0
				Else
					FWrite(nHandle,"Motivo em branco: NumSEQ->" + QRY->D3_NUMSEQ + CRLF)
				EndIf
			Else
				FWrite(nHandle,"Não encontrado registro na SD3: NumSEQ->" + QRY->D3_NUMSEQ + CRLF)
			EndIf//SEEK
		Else
			FWrite(nHandle,"Não encontrado registro na SD7: NumSEQ->" + QRY->D3_NUMSEQ + CRLF)
		EndIf
		QRY->(dbSkip())
	EndDo

	QRY->(dbCloseArea())
	SD3->(dbCloseArea())
	SD7->(dbCloseArea())
	FWrite(nHandle,"Fim da Gravação Log "+Time()+ CRLF)
	FClose(nHandle)

	RESET ENVIRONMENT
Return()
