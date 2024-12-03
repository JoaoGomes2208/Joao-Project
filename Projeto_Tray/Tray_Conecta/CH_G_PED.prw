#Include "Totvs.ch"

/*/{Protheus.doc} CH_G_PED
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
aCabec = Vetor com cabeçalho do execauto
aItens = Vetor com item do execauto
aErros = Vetor para incluir erros de validação

*/

User Function CH_G_PED(oPedido,aCabec,aItens,aErros)

	// Local nPosVend := aScan(aCabec,{|x| Alltrim(x[1]) == "C5_VEND1"})

	aAdd(aCabec, {"C5_TABELA" , GetNewPar("MV_XTBPTRA", "159")  , NIL})
	aAdd(aCabec, {"C5_XORIGEM", "Tray" 							, NIL})
	aAdd(aCabec, {"C5_XNUMINT", oPedido['codigoParceiro']   	, NIL})

Return {aCabec,aItens,aErros}
