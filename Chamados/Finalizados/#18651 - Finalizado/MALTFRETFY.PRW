#include "topconn.ch"
#include "protheus.ch"
/*/{Protheus.doc} MALTTFF()
(long_description)
@type  Function
@author JOAO GOMES
@since 02/09/2024
@example
(examples)
@see (links_or_references)
    /*/
User Function MALTTFF()
	Local oDlgPar   := NIL
	// Monta a tela
	DEFINE MSDIALOG oDlgPar TITLE "Transportadora-FreteFy" FROM 001,001 TO 240,380 PIXEL
	@ 021,035 SAY "Clique no botao OK para alterar as transportadoras" SIZE 150,09 PIXEL OF oDlgPar
	@ 031,035 SAY "no protheus, conforme foram alteradas no FreteFy" SIZE 150,09 PIXEL OF oDlgPar
	@ 041,035 SAY "---------------------------------------------------------------------"   SIZE 200,09 PIXEL OF oDlgPar
	DEFINE SBUTTON FROM 075,68 TYPE 1 ACTION (U_xSchedAltTranspF(),oDlgPar:End()) ENABLE OF oDlgPar
	DEFINE SBUTTON FROM 075,108 TYPE 2 ACTION (oDlgPar:End()) ENABLE OF oDlgPar
	ACTIVATE MSDIALOG oDlgPar CENTERED
Return




