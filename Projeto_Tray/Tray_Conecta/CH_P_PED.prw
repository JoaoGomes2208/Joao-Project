#Include "Totvs.ch"

/*/{Protheus.doc} CH_P_PED
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
oPedido = JSON do Pedido

*/

User Function CH_P_PED(oPedido)

Local aArea := GetArea()
Local i

//numero do pedido do parceiro
If (Valtype(oPedido['codigoErp']) == "C")

    //posiciona no pedido de venda
    SC5->(dbSetOrder(1))
    If SC5->(dbSeek(xFilial("SC5")+Padr(oPedido['codigoErp'],FWSX3Util():GetFieldStruct("C5_NUM")[3])))

        //verifica se tem vetor de pagamento para criação da tabela customizada
        If (Valtype(oPedido['tipospagamento']) == "A")
        
            For i:= 1 to Len(oPedido['tipospagamento'])

                //verifica se os valores necessarios foram passados
                if (ValType(oPedido['tipospagamento'][i]['nsu']) == "C")
                    
                    RecLock('SC5',.F.)
                    SC5->C5_XNSU	:= oPedido['tipospagamento'][i]['nsu']
                    SC5->(msUnLock())
                   
                EndIf
               
            Next

        EndIf

    EndIf

EndIf

//retorna a area
RestArea(aArea)

Return {oPedido}
