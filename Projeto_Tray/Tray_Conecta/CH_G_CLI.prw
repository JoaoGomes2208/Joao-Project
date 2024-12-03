#Include "Totvs.ch"

/*/{Protheus.doc} CH_G_CLI
@author Wlysses Cerqueira
@since 11/03/2024
@version 1.0
/*/

/*
aDados = Vetor com dados do execauto
aErros = Vetor para incluir erros de validação

*/

User Function CH_G_CLI(oCliente,aDados,nOpca,aErros)

	Local nPosEst	:= aScan(aDados,{|x| Alltrim(x[1]) == "A1_EST"})
	Local nPosCep	:= aScan(aDados,{|x| Alltrim(x[1]) == "A1_CEP"})
	Local nPosIbge	:= aScan(aDados,{|x| Alltrim(x[1]) == "A1_IBGE"})
	Local cAlias_   := Nil

	aAdd(aDados, {"A1_PAIS"		, "105"			, Nil})
	aAdd(aDados, {"A1_DDI"		, "55"			, Nil})
	aAdd(aDados, {"A1_NATUREZ"	, "504"			, Nil})
	aAdd(aDados, {"A1_OP"		, "N"			, Nil})
	aAdd(aDados, {"A1_XCLUSTE"	, "N"			, Nil})
	aAdd(aDados, {"A1_RECCOFI"	, "N"			, Nil})
	aAdd(aDados, {"A1_RECCSLL"	, "N"			, Nil})
	aAdd(aDados, {"A1_RECPIS"	, "N"			, Nil})
	aAdd(aDados, {"A1_ABATIMP"	, "3"			, Nil})
	aAdd(aDados, {"A1_CODPAIS"	, "01058"		, Nil})

	aAdd(aDados, {"A1_RECIRRF"	, "2"			, Nil})
	aAdd(aDados, {"A1_GRPTRIB"	, "000"			, Nil})
	aAdd(aDados, {"A1_SIMPLES"	, "2"			, Nil})
	aAdd(aDados, {"A1_SIMPNAC"	, "2"			, Nil})
	aAdd(aDados, {"A1_TPJ"		, "4"			, Nil})
	aAdd(aDados, {"A1_REGIAO"	, "020"			, Nil})
	aAdd(aDados, {"A1_TIPO2"	, "05"			, Nil})
	aAdd(aDados, {"A1_TPESSOA"	, "PF"			, Nil})
	aAdd(aDados, {"A1_RISCO"	, "A"			, Nil})
	aAdd(aDados, {"A1_LC"		, 1000			, Nil})

	aAdd(aDados, {"A1_TIPO2"	, GetNewPar("MV_XTRTIPO", "")	, Nil})
	aAdd(aDados, {"A1_CONTA"	, GetNewPar("MV_XTRCONT", "")	, Nil})

	If nPosCep > 0 .And. !Empty(aDados[nPosCep][2])

		cAlias_ := GetNextAlias()

		BeginSql Alias cAlias_

			SELECT  VAM_IBGE
			FROM    %table:VAM% VAM
			WHERE 	VAM_FILIAL   = %xFilial:VAM%
				AND %Exp:aDados[nPosCep][2]% BETWEEN VAM_CEP1 AND VAM_CEP2
				AND	VAM_ESTADO = %Exp:aDados[nPosEst][2]%
				AND	VAM.%NotDel%
	
		EndSql

		(cAlias_)->(dbGoTop())

		If (cAlias_)->(!EoF())

			If nPosIbge > 0

				If Empty(aDados[nPosIbge][2])

					aDados[nPosIbge][2] := (cAlias_)->VAM_IBGE

				EndIf

			Else

				aAdd(aDados, {"A1_IBGE", (cAlias_)->VAM_IBGE, Nil})

			EndIf

		EndIf

		(cAlias_)->(dbCloseArea())

	EndIf

Return {aDados,nOpca,aErros}
