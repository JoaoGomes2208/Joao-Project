#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_MAR
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
CODIGO
NOME
COMPRADOR

*/

User Function CH_L_MAR(nParamDias)

	Local cQuery := ""

	cQuery += " SELECT"
	cQuery += "     'Prodiet' CODIGO,"
	cQuery += "     'Prodiet' NOME,"
	cQuery += "     row_number() over (order by CODIGO) linha_tabela"

	cQuery += " FROM ( "

	cQuery += "     SELECT TOP 1"
	cQuery += "         SB1.B1_FABRIC CODIGO,"
	cQuery += "         SB1.B1_FABRIC NOME"

	cQuery += "     FROM "+RetSqlName("SB1")+" SB1"

	cQuery += "     WHERE"
	cQuery += "         SB1.B1_FILIAL   = '"+xFilial("SB1")+"'"
	// cQuery += "     AND	SB1.B1_FABRIC   <> ''"
	cQuery += "     AND	SB1.D_E_L_E_T_  = ''"

	cQuery += "     GROUP BY"
	cQuery += "         SB1.B1_FABRIC"

	cQuery += " ) QRY "

Return cQuery
