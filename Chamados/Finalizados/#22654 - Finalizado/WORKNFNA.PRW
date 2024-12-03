#INCLUDE 'protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'tbiconn.ch'
//-----------------------------------------------------------------------------------
/*/{Protheus.doc} WORKNFNA
Envia relação de notas fiscais que estão com status diferentes de danfe impressa. 
@type function

@author Jonatas Paiva
@since 13/11/2020
@version P12 
@return html
/*/
//-----------------------------------------------------------------------------------
User Function WORKNFNA()
	Local aXEmpFil  := {"03","01"}
	Local _cAssunto := ":: Atenção - Notas Fiscais Sem Impressão de Danfe ::"
	Local _cTo      := "ti@prodiet.com.br;fiscal@prodiet.com.br"
	Local _cCab     := ""
	Local _cMsg     := ""
	Local _cRod     := ""
	Local cQuery    := ""
	Private nCont   := 0

	PREPARE ENVIRONMENT EMPRESA aXEmpFil[1] FILIAL aXEmpFil[2] FUNNAME FunName() TABLES "SB9, SB2, SB1"
	cQuery := " SELECT " + CRLF
	cQuery += "	 CASE F2_FIMP WHEN 'S' THEN 'Nota fiscal autorizada' WHEN 'T' THEN 'TRANSMITIDA SEM DANFE' WHEN 'D' THEN 'USO DENEGADO' WHEN 'N' THEN 'NAO AUTORIZADA' ELSE 'NAO TRANSMITIDA' END  AS STATUS_NF, "+ CRLF
	cQuery += "	 F2_FILIAL AS FILIAL, "+ CRLF
	cQuery += "	 F2_DOC AS DOC, "+ CRLF
	cQuery += "	 F2_SERIE AS SERIE, "+ CRLF
	cQuery += "	 'SAIDA' AS TIPO_NF "+ CRLF
	cQuery += " FROM "+RetSqlName("SF2")+" SF2 "+ CRLF
	cQuery += " WHERE "+ CRLF
	cQuery += "	F2_FIMP <> 'S' AND " + CRLF
	cQuery += "	CONVERT(DATE,F2_EMISSAO,103) >= CONVERT(DATE,GETDATE()-30,103) AND "+ CRLF
	cQuery += "	D_E_L_E_T_ = ' ' "

	If (Select ("QRY")<> 0)
		QRY->(DbCloseArea())
	EndIf

	TcQuery cQuery New Alias "QRY"
	_cCab += 		U_Imagem("CabEmail")
	_cCab += 		U_Imagem("CabInfo")
	_cCab += "     <table width='850' border='0' align='left' bgcolor='#ffffff'> "
	_cCab += "       <tbody> "
	_cCab += " 			<p> "
	_cCab += " 			<p>Notas Fiscais que não foram impressas, emitidas nos últimos 30 dias. Verificar urgentemente!</p>"
	_cCab += "       <tr> "
	_cCab += " 		 <td align='justify'> "
	_cCab += "          	 <table class='bottomBorder'> "
	_cCab += "                 <tbody> "
	_cCab += "      <tr class=''>  "
	_cCab += "			<th>Status</th> "
	_cCab += " 			<th>Filial</th> "
	_cCab += "			<th>Nota Fiscal</th> "
	_cCab += "			<th>Serie</th> "
	_cCab += "      </tr> "

	QRY->(DbGoTop())
	While QRY->(!EOF())
		_cMsg+= "  <tr>"
		_cMsg+= "    <td>" + QRY->STATUS_NF + " </td> "
		_cMsg+= "    <td>" + QRY->FILIAL + " </td> "
		_cMsg+= "    <td>" + QRY->DOC + " </td> "
		_cMsg+= "    <td>" + QRY->SERIE + " </td> "
		_cMsg+= "  </tr> "
		nCont ++
		QRY->(DbSkip())
	EndDo

	_cRod += 			U_Imagem("RodEmail")
	_cRod += 			U_Imagem("RodInfo")

	If nCont > 0
		U_SendEMail(,,,,_cTo,_cAssunto,_cCab + _cMsg + _cRod,)
		//conout("WorkNFNA - E-mail enviado.")
		FWLogMsg("INFO", /*cTransactionId*/, "Sched", "WorkNFNA", /*cStep*/, /*cMsgId*/, "E-mail enviado.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		//conout("WorkNFNA - Não tem Arquivo.")
		FWLogMsg("INFO", /*cTransactionId*/, "Sched", "WorkNFNA", /*cStep*/, /*cMsgId*/, "Não tem Arquivo.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Return()


/*/{Protheus.doc} xMailTrocaFilial
(Envia relatorio de documentos que foram transferidos mais estão com erro.)
@type user function
@author Joao Gomes
@since 16/10/2024
@version 1.0
/*/
User Function xMailTrocaFilial()

	Local cQry01 := ""
	Local cQry02 := ""
	Local aDocD1 := {}
	Local aDocD2 := {}
	Local aNotInteD1:={}
	Local aNotInteD2:={}
	Local _cAssunto := ":: Atenção - Documentos com transferencia de filial não encontradas ::"
	Local _cTo      := "ti@prodiet.com.br;fiscal@prodiet.com.br"
	Local _cCab     := ""
	Local _cMsg     := ""
	Local _cRod     := ""
	Local nX		:= 0
	Local nDoc		:= 0
	Local cDataDe	:= DToS(Date()-30)
	Local cDataAte	:= DToS(Date())

	//Dados da SD1 do ultimos mês
	cQry01:= " SELECT " + CRLF
	cQry01+= " D1_FILIAL ," + CRLF
	cQry01+= " D1_DOC DOCENTRADA " + CRLF
	cQry01+= " FROM SD1030 D1 " + CRLF
	cQry01+= " WHERE " + CRLF
	cQry01+= " D1_EMISSAO BETWEEN "+cDataDe+" AND " +cDataAte + CRLF
	cQry01+= " AND D1.D_E_L_E_T_ = '' " + CRLF
	cQry01+= " AND SUBSTRING(D1.D1_CF,2,3) IN ('151','152') " + CRLF
	cQry01+= " GROUP BY D1_FILIAL,D1_DOC " + CRLF
	cQry01+= " ORDER BY D1_FILIAL,D1_DOC " + CRLF

	If (Select ("QRY01")<> 0)
		QRY->(DbCloseArea())
	EndIf
	TcQuery cQry01 New Alias "QRY01"
	QRY01->(DBGOTOP())

	//Armazena os dados da D1 no array
	While QRY01->(!Eof())
		AAdd(aDocD1, {QRY01->D1_FILIAL, QRY01->DOCENTRADA})
		QRY01->(DbSkip())
	EndDo
	QRY01->(DbCloseArea())

	//Dados da SD2 do ultimos mês
	cQry02:= " SELECT " + CRLF
	cQry02+= " D2_FILIAL ," + CRLF
	cQry02+= " D2_DOC DOCSAIDA " + CRLF
	cQry02+= " FROM SD2030 D2 " + CRLF
	cQry02+= " WHERE " + CRLF
	cQry02+= " D2_EMISSAO BETWEEN "+cDataDe+" AND " +cDataAte + CRLF
	cQry02+= " AND D2.D_E_L_E_T_ = '' " + CRLF
	cQry02+= " AND SUBSTRING(D2.D2_CF,2,3) IN ('151','152') " + CRLF
	cQry02+= " GROUP BY D2_FILIAL,D2_DOC " + CRLF
	cQry02+= " ORDER BY D2_FILIAL,D2_DOC " + CRLF

	If (Select ("QRY02")<> 0)
		QRY->(DbCloseArea())
	EndIf
	TcQuery cQry02 New Alias "QRY02"
	QRY02->(DBGOTOP())

	//Armazena os dados da D2 no array
	While QRY02->(!Eof())
		AAdd(aDocD2, {QRY02->D2_FILIAL, QRY02->DOCSAIDA})
		QRY02->(DbSkip())
	EndDo
	QRY02->(DbCloseArea())

	//Faz a verificação se os DOC da D1 foram encontrados na D2
	For nX := 1 to Len(aDocD1)
		nDoc := AScan(aDocD2,{|x| AllTrim(x[2]) == aDocD1[nX][2]},,)
		If !Empty(nDoc)
			If aDocD2[nDoc][1] == aDocD1[nX][1]
				AAdd(aNotInteD1,{aDocD1[nX][1],aDocD1[nX][2]})
			EndIf
		Else
			AAdd(aNotInteD1,{aDocD1[nX][1],aDocD1[nX][2]})
		EndIf

	Next

	//Faz a verificação se os DOC da D2 foram encontrados na D1
	For nX := 1 to Len(aDocD2)
		nDoc := AScan(aDocD1,{|x| AllTrim(x[2]) == aDocD2[nX][2]},,)
		If !Empty(nDoc)
			If aDocD1[nDoc][1] == aDocD2[nX][1]
				AAdd(aNotInteD2,{aDocD2[nX][1],aDocD2[nX][2]})
			EndIf
		Else
			AAdd(aNotInteD2,{aDocD2[nX][1],aDocD2[nX][2]})
		EndIf
	Next

	If Len(aNotInteD1) > 0 .OR. Len(aNotInteD2) > 0
		_cCab += 		U_Imagem("CabEmail")
		_cCab += 		U_Imagem("CabInfo")
		_cMsg += "     <table width='850' border='0' align='left' bgcolor='#ffffff'> "
		_cMsg += "       <tbody> "
		_cMsg += " 			<p> "
		_cMsg += " 			<p>Documentos transferidos de uma filial para outra com erro: </p>"
		_cMsg += "       <tr> "
		_cMsg += " 		 <td align='justify'> "
		_cMsg += "          	 <table class='bottomBorder'> "
		_cMsg += "                 <tbody> "

		If Len(aNotInteD1) > 0
			_cMsg += " <br>"
			_cMsg += " <p>Está na lista de <b>ENTRADAS</b>, mas não está na lista <b>SAIDA</b>: Faltou registarar a <b>SAIDA</b> </p>"
			_cMsg += "      <tr class=''>  "
			_cMsg += "			<th>Tipo</th> "
			_cMsg += "			<th>Filial</th> "
			_cMsg += " 			<th>Documento</th> "
			_cMsg += "      </tr> "
			For nX := 1 to Len(aNotInteD1)
				_cMsg+= "  <tr>"
				_cMsg+= "	 <td> Falta Saida </td> "
				_cMsg+= "    <td>" + aNotInteD1[nX][1] + " </td> "
				_cMsg+= "    <td>" + aNotInteD1[nX][2] + " </td> "
				_cMsg+= "  </tr> "
			Next
			_cMsg+= "  </table> "
		EndIf

		If Len(aNotInteD2) > 0
			_cMsg += " <br>"
			_cMsg += " <table class='bottomBorder'> "
			_cMsg += " <p>Está na lista de <b>SAIDAS</b>, mas não está na lista de <b>ENTRADAS</b> Faltou registarar a <b>ENTRADA<b> </p>"
			_cMsg += "      <tr class=''>  "
			_cMsg += "			<th>Tipo</th> "
			_cMsg += "			<th>Filial</th> "
			_cMsg += " 			<th>Documento</th> "
			_cMsg += "      </tr> "
			For nX := 1 to Len(aNotInteD2)
				_cMsg+= "  <tr>"
				_cMsg+= "	 <td> Falta Entrada </td> "
				_cMsg+= "    <td>" + aNotInteD2[nX][1] + " </td> "
				_cMsg+= "    <td>" + aNotInteD2[nX][2] + " </td> "
				_cMsg+= "  </tr> "
			Next
		EndIf

		_cRod += 			U_Imagem("RodEmail")
		_cRod += 			U_Imagem("RodInfo")

		U_SendEMail(,,,,_cTo,_cAssunto,_cCab + _cMsg + _cRod,)
		//conout("WorkNFNA - E-mail enviado.")
		FWLogMsg("INFO", /*cTransactionId*/, "Sched", "WorkNFNA", /*cStep*/, /*cMsgId*/, "E-mail transferencia de filial enviado.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	EndIf

Return
