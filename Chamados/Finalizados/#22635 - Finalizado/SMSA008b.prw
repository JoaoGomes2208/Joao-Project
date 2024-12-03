#Include "Protheus.ch"
#include 'rwmake.ch'
#include 'topconn.ch'
#include 'tbiconn.ch'

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} SMSA008
Ponto de entrada: Realiza a impressão da etiqueta via Documento de Entrada

@author    Alfred Andersen
@version   1.00
@since     07/12/2018

/*/
User Function SMSA008b()

	LOCAL _cAlias	:= GetNextAlias()
	Local _lImp		:= .F.
	Local oMark
	Local oBrowse
	Local oImgMark
	Local oImgDMark
	Local aMarked	:= {}
	Local nX

	Private _oDlgCon
	Private _aProd	:= {}
	Private lMarcar	:= .T.
	Private Exec    := .F.

	BeginSQL Alias _cAlias
		SELECT D1_COD,B1_DESC ,D1_QUANT, D1_LOTECTL, D1_DTVALID, D1_UM, B1_QE
		FROM %Table:SD1% SD1
		INNER JOIN %Table:SB1% SB1 ON B1_COD = D1_COD AND SB1.%NotDel%
		WHERE D1_FILIAL = %Exp:SF1->F1_FILIAL%
		AND D1_DOC = %Exp:SF1->F1_DOC%
		AND D1_SERIE = %Exp:SF1->F1_SERIE%
		AND D1_FORNECE = %Exp:SF1->F1_FORNECE%
		AND D1_LOJA = %Exp:SF1->F1_LOJA%
		AND D1_TP = 'MP'
		AND SD1.%NotDel%
		ORDER BY D1_ITEM
	EndSQL

	//Resultado da Query
	_cResQry:= GETLastQuery()[2]

	If (_cAlias)->(!Eof())
		While (_cAlias)->(!Eof())

			Aadd(_aProd,{.F.,(_cAlias)->D1_COD,(_cAlias)->B1_DESC,(_cAlias)->D1_LOTECTL,(_cAlias)->D1_DTVALID,(_cAlias)->D1_QUANT,(_cAlias)->D1_UM,(_cAlias)->B1_QE})
			(_cAlias)->(dbSkip())
		EndDo

		If Len(_aProd) > 0

			// Monta a tela de consulta
			DEFINE MSDIALOG _oDlgCon TITLE "Impressão de Etiquetas" FROM 000,000 TO 400,800 OF oMainWnd PIXEL

			@015,002 TO 175,400 PROMPT " Itens disponíveis para impressão" OF _oDlgCon PIXEL
			//_oDlgCon:lMaximized := .T.

			oImgMark 	:= LoadBitmap(GetResources(),'LBTIK')
			oImgDMark	:= LoadBitmap(GetResources(),'LBNO')

			//Grid do dados do produto
			oBrowse := TCBrowse():New( 025 , 004, 390, 145,,{"","Código","Descrição","Lote","Validade","Quantidade"},;
				{070,035,070,060},_oDlgCon,,,,,{||},,,,,,,.F.,,.T.,,.F.,,,)

			//oBrowse:lAdjustColSize 	:= .T.
			oBrowse:bLDblClick		:= {|nRow, nCol| _aProd[oBrowse:nAt,01] := !_aProd[oBrowse:nAt,01]}
			oBrowse:bHeaderClick	:= {|nRow, nCol| If(nCol == 1,(lMarcacao(),oBrowse:Refresh()),Nil) }

			oBrowse:SetArray(_aProd)
			oBrowse:bLine := {||{If(_aProd[oBrowse:nAt,01],oImgMark,oImgDMark), _aProd[oBrowse:nAt,02],_aProd[oBrowse:nAt,03],_aProd[oBrowse:nAt,04],DTOC(STOD(_aProd[oBrowse:nAt,05])),cValToChar(_aProd[oBrowse:nAt,06])}}

			@ 180,320 BMPBUTTON TYPE 01 ACTION (Exec := .T.,Close(_oDlgCon))
			@ 180,350 BMPBUTTON TYPE 02 ACTION (Exec := .F.,Close(_oDlgCon))

			ACTIVATE MSDIALOG _oDlgCon CENTER

			If Exec
				For nX:=1 To Len(_aProd)
					If _aProd[nX][1]
						If !EMPTY(_aProd[nX][1])
							ADEL(_aProd[nX],1)
							AADD(aMarked,aClone(_aProd[nX]))
						EndIf
					EndIf
				Next

				If Len(aMarked) > 0
					U_SMSA008A(aMarked)
				EndIf
			EndIf
		EndIf
	Else
		MsgAlert("Os produtos que constam nesta nota não atendem aos requisitos para impressão da etiqueta!","NOETIQUETA")
	Endif

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} lMarcacao
Controla a marcação da tela de seleção

@author    Alfred Andersen
@version   1.00
@since     04/02/2019

/*/
Static Function lMarcacao()
	Local nX
	
	For nX:= 1 To Len(_aProd)
		_aProd[nX][1] := lMarcar
	Next

	lMarcar := !lMarcar

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} SMSA008A
Rotina gerencial de impressão da etiqueta

@author    Alfred Andersen
@version   1.00
@since     04/02/2019

/*/
User Function SMSA008A(_aItens)

	//Local _lRet 	:= .T.
	Local _nX
	Local nY
	Local cPorta    := GetNewPar("MV_ZEBPORT","LPT1")
	Local cModelo   := "ZEBRA"
	Local nColIni 	:= GetNewPar("MV_XSMS08A",6)
	Local nLinIni 	:= 3
	//Local nLargMax  := 98
	//Local nAltMax   := 78
	//Local nMargEsq  := 3
	//Local nMargDir  := 3
	Local _nInc 	:= 10
	Local _nEtiq	:= 0
	Private _cCodBar	:= ""

	//Net use LPT1 \\nome_do_micro\nome_do_compartilhamento

	//Analisa os itens a serem impressos
	For _nX := 1 to Len(_aItens)

		//Compõem código de barras
		_cCodBar := ALLTRIM(_aItens[_nX][1])+ALLTRIM(_aItens[_nX][3])

		//Calcula quantas etiquetas deverão ser impressas
		//Quantidade comprada / quantidade por embalagem
		_nEtiq := _aItens[_nX][5] / _aItens[_nX][7]

		//Calcula o resto da divisao
		_nRest := _aItens[_nX][5] % _aItens[_nX][7]





		//Realiza a impressão da etiqueta para a quantidade de embalagem configurada no cadastro do produto
		For _nY := 1 to _nEtiq
			// Efetua a impressão
			MSCBPRINTER(cModelo,CPorta, , 40   ,.f.)

			MSCBCHKSTATUS(.F.)

			MSCBBEGIN(1,6)

			MSCBSAY(nColIni		, nLinIni          ,"COD: "+_aItens[_nX][1], "N", "0", "080,050",,,,,.T.)
			MSCBSAY(nColIni		, nLinIni+(_nInc*1),"ITEM: "+_aItens[_nX][2], "N", "0", "070,050",,,,,.T.)
			MSCBSAY(nColIni		, nLinIni+(_nInc*2),"LOTE: "+_aItens[_nX][3], "N", "0","070,050",,,,,.T.)
			MSCBSAY(nColIni		, nLinIni+(_nInc*3),"VAL: "+DTOC(STOD(_aItens[_nX][4])), "N", "0", "070,050",,,,,.T.)
			MSCBSAY(nColIni*10	, nLinIni+(_nInc*3),"QTD: "+CvalToChar(_aItens[_nX][7])+" "+_aItens[_nX][6], "N", "0", "070,050",,,,,.T.)

			Gerabarra()
			MSCBEND()
		Next _nY

		//Caso a divisão tenha sobras, realiza a impressão da última etiqueta com a quantidade menor
		If _nRest > 0
			// Efetua a impressão
			MSCBPRINTER(cModelo,CPorta, , 40   ,.f.)

			MSCBCHKSTATUS(.F.)

			MSCBBEGIN(1,6)

			MSCBSAY(nColIni		, nLinIni          ,"COD: "+_aItens[_nX][1], "N", "0", "080,050",,,,,.T.)
			MSCBSAY(nColIni		, nLinIni+(_nInc*1),"ITEM: "+_aItens[_nX][2], "N", "0", "070,050",,,,,.T.)
			MSCBSAY(nColIni		, nLinIni+(_nInc*2),"LOTE: "+_aItens[_nX][3], "N", "0","070,050",,,,,.T.)
			MSCBSAY(nColIni		, nLinIni+(_nInc*3),"VAL: "+DTOC(STOD(_aItens[_nX][4])), "N", "0", "070,050",,,,,.T.)
			MSCBSAY(nColIni*10	, nLinIni+(_nInc*3),"QTD: "+CvalToChar(_nRest)+" "+_aItens[_nX][6], "N", "0", "070,050",,,,,.T.)
			//MSCBSAYBAR(nColIni	, nLinIni+(_nInc*4),_cCodBar,"N","MB07",13,.f.,.t.,,,3,2,.t.) //monta codigo de barras
			//MSCBWrite('B586,165,2,1,2,6,113,B,"'+_cCodBar+'"'+CHR(13)+CHR(10))

			GeraBarra()

			MSCBEND()
		EndIf

	Next _nX

	MSCBCLOSEPRINTER()

Return

Static Function GeraBarra

	MSCBWrite('^FO100,330^BY3,1,96^BCMB07, 96,Y,N,N,N^FD'+_cCodBar+'^FS'+CHR(13)+CHR(10))

Return
