#include "rwmake.ch"
#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"
#include "TBICONN.ch"



/*/{Protheus.doc} xCHFINA040
(Rotina de schedule que chama a função que cria titulos AB- no protheus)
@type user function
@author Joao Gomes
@since 15/08/2024
@version 1.0
@see (links_or_references)
@params dDataini - inicio das verificacoes
@params dDataFim - fim das verificacoes
/*/
User Function xCHFIN040()

	Local cDataDe
	Local cDataAte
	Local cQry
	Local aLista := {}
	Local lRet := .F.
	//Local aArea := getArea()

	PREPARE ENVIRONMENT EMPRESA '03' FILIAL '03' FUNNAME FunName() TABLES 'SC5'
	FWLogMsg("INFO", /*cTransactionId*/, "Financeiro", "xCHFIN040", /*cStep*/, /*cMsgId*/, "Inicio da rotina FINA040", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	cDataDe := DtoS(Date()-7)
	cDataAte := DtoS(Date())
	

	cQry := "SELECT C5_NUM, C5_CONDPAG, C5_XNSU, C5_XORIGEM, C5_EMISSAO, C5_NOTA, C5_FILIAL FROM " + RetSqlName("SC5") + " " + CRLF
	cQry += "WHERE C5_XNSU != '' " + CRLF
	cQry += "AND C5_NOTA != '' " + CRLF
	cQry += "AND UPPER(C5_XORIGEM) = 'TRAY' " + CRLF
	cQry += "AND C5_EMISSAO BETWEEN '" + cDataDe + "' AND '" + cDataAte + "'" + CRLF
	cQry += "AND C5_XINTTR = '' "

	If Select("CQRY2") <> 0
		DbSelectArea("CQRY2")
		DbCloseArea()
	EndIf

	TCQuery cQry New Alias "CQRY2"

	WHILE CQRY2->(!Eof())
		aAdd(aLista, CQRY2->C5_XNSU)
		aAdd(aLista, CQRY2->C5_NUM)
		aAdd(aLista, CQRY2->C5_CONDPAG)
		aAdd(aLista, cDataDe)
		aAdd(aLista, cDataAte)
		lRet := U_xExFINA040(aLista)

		if lRet == .T.
			FWLogMsg("INFO", /*cTransactionId*/, "Financeiro", "xCHFIN040", /*cStep*/, /*cMsgId*/, "Erro ao fazer a inclusao do AB- do pedido: " + CQRY2->C5_NUM, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)//Verificar se da pra fazer uma função de log
		Else
			FWLogMsg("INFO", /*cTransactionId*/, "Financeiro", "xCHFIN040", /*cStep*/, /*cMsgId*/, "Inclusao do AB- do pedido: " + CQRY2->C5_NOTA + "feita com sucesso", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			DbSelectArea("SC5")
			DbSetOrder(1)
			If SC5->(DbSeek(CQRY2->C5_FILIAL+CQRY2->C5_NUM))
				RecLock('SC5',.F.)
				SC5->C5_XINTTR := '*' //Inclusao para marcar que ja foi gerado o AB-
				SC5->(MsUnlock())
			EndIf
		EndIf
		aSize(aLista,0)
		CQRY2->(DBSkip())
	End
	RESET ENVIRONMENT
Return
