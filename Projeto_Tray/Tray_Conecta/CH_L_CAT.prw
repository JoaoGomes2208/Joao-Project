#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_VEND
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
CODIGO
NOME

*/

User Function CH_L_CAT(nParamDias)

	Local cQuery := ""

	cQuery += " SELECT "
	cQuery += "     SBM.BM_GRUPO                    CODIGO,"
	cQuery += "     REPLACE(SBM.BM_DESC,'/',' ')    NOME,"
	cQuery += "     row_number() over (order by SBM.BM_FILIAL, SBM.BM_GRUPO) linha_tabela"

	cQuery += " FROM "+RetSqlName("SBM")+" SBM"

	cQuery += " WHERE"
	cQuery += "     SBM.BM_FILIAL   = '"+xFilial("SBM")+"'"
	cQuery += " AND	SBM.D_E_L_E_T_  = ''"

Return cQuery
