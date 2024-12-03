#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MbrwSB8E
Tela para tabela SB8
@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------

User function MbrwSB8E()

	Local _cAlias		:= "SB8"
	Local _cFiltro		:= "B8_SALDO > 0"
	Private aRotina 	:= {}

//adiciona chamada no aRotina
	AADD(aRotina, { "Pesquisar"		, "AxPesqui"	, 0, 1 })
	AADD(aRotina, { "Etiqueta"      , "U_xImpSB8"   , 0, 2 })


	dbSelectArea(_cAlias)
	dbSetOrder(1)

	mBrowse( ,,,,_cAlias,,,,,,,,,,,,,,_cFiltro)

Return Nil
/*/{Protheus.doc} xImpSB8
Monta dados para imprimir etiqueta

@author    Jonatas Paiva
@version   1.00
@since     ${date}

Alteração 21/10/2024
Adicionado variaveis de fração e inteiro para suprir necessidade do PCP
@author Joao Gomes
/*/
User Function xImpSB8()

	Local _aProd := {}
	Local _aItens:= {"Inteiro","Fração"}
	Local _cCombo:= _aItens[1]
	Local _aArea := GetArea()
	Local _cProd := SB8->B8_PRODUTO
	Local _cLote := SB8->B8_LOTECTL
	Local _cValid:= DTOC(SB8->B8_DTVALID)
	Local _cUM	 := ""
	Local _cDesc := ""
	Local _nQtde := 0
	Local _nQTEmb:= 0
	Local _nEtiqu:= 0
	Local _nResto:= 0
	Local _lExec := .F.
	Local oGet1
	Local oGet2
	Local oGet3
	Local oGet4
	Local oGet5
	Local oGet6
	Local oGet7
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oSay7
	Local oCombo
	Static oDlg

	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
	SB1->(dbGoTop())

	If SB1->(dbSeek(xFilial("SB1")+_cProd))

		_cUM	:= SB1->B1_UM
		_cDesc := SB1->B1_DESC
		_nQTEmb:= SB1->B1_QE


		DEFINE MSDIALOG oDlg TITLE "Dados da Impressão" FROM 000, 000  TO 400, 400 COLORS 0, 16777215 PIXEL

		oCombo:= tComboBox():New(002,045,{|u|if(PCount()>0,_cCombo:=u,_cCombo)},_aItens,090,015,oDlg,,,,,,.T.,,,,,,,,,'_cCombo')

		@ 005, 007 SAY oSay7 PROMPT "Tp Operação" SIZE 040, 030 OF oDlg COLORS 0, 16777215 PIXEL
		@ 020, 007 SAY oSay1 PROMPT "Produto" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 035, 007 SAY oSay2 PROMPT "Descrição" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 050, 007 SAY oSay3 PROMPT "Lote" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 065, 007 SAY oSay4 PROMPT "Validade" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 080, 007 SAY oSay5 PROMPT "UM" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 095, 007 SAY oSay6 PROMPT "Qtde. "+_cUM SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 110, 007 SAY oSay8 PROMPT "Nº Etiquetas" SIZE 040, 030 OF oDlg COLORS 0, 16777215 PIXEL
		@ 017, 045 MSGET oGet1 VAR _cProd SIZE 060, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
		@ 032, 045 MSGET oGet2 VAR _cDesc SIZE 149, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
		@ 047, 045 MSGET oGet3 VAR _cLote SIZE 149, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
		@ 062, 045 MSGET oGet4 VAR _cValid SIZE 060, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
		@ 077, 045 MSGET oGet5 VAR _cUM SIZE 025, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
		@ 092, 045 MSGET oGet6 VAR _nQtde SIZE 061, 010 OF oDlg COLORS 0, 16777215 PIXEL PICTURE "@E 999,999.999"
		@ 107, 045 MSGET oGet7 VAR _nEtiqu SIZE 025, 010 OF oDlg COLORS 0, 16777215 PIXEL PICTURE "@E 999"
		@ 145, 157 BMPBUTTON TYPE 01 ACTION (_lExec := .T.,Close(oDlg))
		@ 145, 115 BMPBUTTON TYPE 02 ACTION (_lExec := .F.,Close(oDlg))

		ACTIVATE MSDIALOG oDlg CENTERED

		If _lExec
			If _cCombo == "Inteiro"
				_nEtiqu := int(_nQtde  / _nQTEmb)
				_nResto := _nQtde % _nQTEmb
				If (_nQtde > 0 .and. ((_nEtiqu > 0 .and. _nEtiqu < 50) .or. ( _nResto > 0)))
					If MsgYesNo("Será impresso do Cód:"+_cProd+ " Lote:"+_cLote + CRLF +;
							iif(_nEtiqu>0, cValToChar(_nEtiqu)  + " etiqueta(s) de " + cValToChar(_nQTEmb) + " " + _cUM,"" + CRLF )+;
							iif(_nResto>0," 1 etiqueta de " + cValToChar(_nResto) + _cUM + " como fração."+ CRLF ,"")+;
							"Confirma ?","Impressão de Etiqueta")
						//Adiciona ao array para enviar a impressao da etiqueta no fonte SBSA008
						_cValid := DTOS(CTOD(_cValid))
						Aadd(_aProd,{_cProd,_cDesc,_cLote,_cValid,_nQtde,_cUM,_nQTEmb})
						U_SMSA008A(_aProd)
					EndIf
				Else
					Alert("Quantidade deve ser maior que Zero ou Menor que 50 Etiquetas por Vez!")
				EndIf
			Else
				If MsgYesNo("Será impresso do Cód: "+_cProd+ " Lote:"+_cLote + CRLF +;
						iif(_nEtiqu>0, cValToChar(_nEtiqu)  + " etiqueta(s) de " + cValToChar(_nQtde) + " " + _cUM,"" + CRLF )+;
						"Confirma ?","Impressão de Etiqueta")
					_cValid := DTOS(CTOD(_cValid))
					Aadd(_aProd,{_cProd,_cDesc,_cLote,_cValid,_nQtde,_cUM,_nQTEmb,_nEtiqu})
					U_xGeraEtiqueta(_aProd)
				EndIf
			EndIf
		Else
			MsgInfo("Operação Cancelada!","Informativo")
		EndIf

	Else
		Alert("Produto não encontrado!")
	EndIf


	SB1->(dbCloseArea())
	RestArea(_aArea)

Return Nil


//--< fim de arquivo >----------------------------------------------------------------------


