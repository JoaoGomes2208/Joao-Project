#Include "Protheus.ch"
#Include "totvs.ch"
#Include "topconn.ch"

//-------------------------------------------------------------------
/*{Protheus.doc} INCLUSAO_Z41
Popula tabela Z41
@author  Joao Gomes
@since   23/09/2024
@version 1.0
*/
//-------------------------------------------------------------------
User Function PopulaZ41()
	Local cArqCSV := "C:\Users\jvitor\OneDrive - Prodiet Nutricao Clinica Ltda\Área de Trabalho\Lista_Municipios_Brasil.txt" // Especifique o caminho para o arquivo CSV
	Local oFile as Object
	Local aArq := {}
    Local cLinDec := ""
    Local i := 1

	oFile := FWFileReader():New(cArqCSV)
	//Se o arquivo pode ser aberto
	If (oFile:Open())

		//Se não for fim do arquivo
		If ! (oFile:EoF())
			//Enquanto houver linhas a serem lidas
			While (oFile:HasLine())

				//Buscando o texto da linha atual
                cLinDec := DecodeUTF8(oFile:GetLine(),"cp1252")
                if ValType(cLinDec) != 'C'
                    cLinDec := DecodeUTF8(oFile:GetLine(),"cp1252")
                endif

				AADD(aArq, StrTokArr(cLinDec, ';')) 

			EndDo
		EndIf
	EndIf

	//Fecha o arquivo e finaliza o processamento
	oFile:Close()

    nWhile := Len(aArq)
	// Ler o conteúdo do arquivo linha por linha
	While i<=nWhile
		// Manipular os dados e popular a tabela Z41 com RECKLOCK
		DbSelectArea("Z41")       
        RecLock("Z41",.T.)
		    Z41->Z41_EST    := aArq[i][1]
		    Z41->Z41_DESCES := aArq[i][2]
		    Z41->Z41_CODCID := aArq[i][3]
		    Z41->Z41_DESCCI := aArq[i][4]
        Z41->(MsUnlock())
        i++
	End
	MsgInfo("Importação concluída com sucesso!", "Sucesso")
Return
