#ifdef SPANISH
	#define STR0001 "Vehiculos por listarse a la atencion"
	#define STR0002 "Grupo del modelo"
	#define STR0003 "Modelo deseado"
	#define STR0004 "Color deseada"
	#define STR0005 "Valor"
	#define STR0006 "Dias"
	#define STR0007 "Modelo"
	#define STR0008 "Color"
	#define STR0009 "Fab/Mod"
	#define STR0010 "Combustible"
	#define STR0011 "Opcionales Fabrica"
	#define STR0012 "Chasis"
	#define STR0013 "Tipo"
	#define STR0014 "Progreso"
	#define STR0015 "Stock"
	#define STR0016 "Transito"
	#define STR0017 "Atencion"
	#define STR0018 "Valor del vehiculo divergente. �Imposible seguir!"
	#define STR0019 "Vehiculo seleccionado"
	#define STR0020 "Atencion Venta Futura"
	#define STR0021 "�Desea vincular el vehiculo a la atencion?"
	#define STR0022 "Pedido"
	#define STR0023 "�Usuario sin permiso para seleccionar veh�culos en la Venta futura!"
	#define STR0024 "Valor del veh�culo divergente. �Desea actualizar valor de Venta del veh�culo en el Archivo de veh�culos con el avalor de venta de esta atenci�n?"
#else
	#ifdef ENGLISH
		#define STR0001 "Vehicles to associate with the service"
		#define STR0002 "Model Group"
		#define STR0003 "Desired model"
		#define STR0004 "Desired color"
		#define STR0005 "Value"
		#define STR0006 "Days"
		#define STR0007 "Model"
		#define STR0008 "Color"
		#define STR0009 "Manuf./Mod."
		#define STR0010 "Fuel"
		#define STR0011 "Factory Optional Items"
		#define STR0012 "Chassis"
		#define STR0013 "Type"
		#define STR0014 "Progress"
		#define STR0015 "Inventory"
		#define STR0016 "Transit"
		#define STR0017 "Attention"
		#define STR0018 "Different vehicle value. Cannot continue!"
		#define STR0019 "Vehicle selected"
		#define STR0020 "Future Sales Service"
		#define STR0021 "Do you want to associate the Vehicle with the Service?"
		#define STR0022 "Order"
		#define STR0023 "User without permission to select vehicles in Future Sales!"
		#define STR0024 "Vehicle different value. Update sales value of vehicle in vehicles register with sales values of this service?"
	#else
		#define STR0001 If( cPaisLoc $ "ANG|PTG", "Ve�culos a relacionar ao Atendimento", "Veiculos a relacionar ao Atendimento" )
		#define STR0002 "Grupo do Modelo"
		#define STR0003 "Modelo desejado"
		#define STR0004 "Cor desejada"
		#define STR0005 "Valor"
		#define STR0006 "Dias"
		#define STR0007 "Modelo"
		#define STR0008 "Cor"
		#define STR0009 "Fab/Mod"
		#define STR0010 If( cPaisLoc $ "ANG|PTG", "Combust�vel", "Combustivel" )
		#define STR0011 If( cPaisLoc $ "ANG|PTG", "Opcionais F�brica", "Opcionais Fabrica" )
		#define STR0012 "Chassi"
		#define STR0013 "Tipo"
		#define STR0014 "Progresso"
		#define STR0015 If( cPaisLoc $ "ANG|PTG", "Stock", "Estoque" )
		#define STR0016 "Transito"
		#define STR0017 "Aten��o"
		#define STR0018 If( cPaisLoc $ "ANG|PTG", "Valor do ve�culo divergente. Imposs�vel continuar!", "Valor do veiculo divergente. Impossivel continuar!" )
		#define STR0019 If( cPaisLoc $ "ANG|PTG", "Ve�culo seleccionado", "Veiculo selecionado" )
		#define STR0020 "Atendimento Venda Futura"
		#define STR0021 If( cPaisLoc $ "ANG|PTG", "Deseja relacionar o Ve�culo ao Atendimento?", "Deseja relacionar o Veiculo ao Atendimento?" )
		#define STR0022 "Pedido"
		#define STR0023 "Usu�rio sem permiss�o para selecionar ve�culos na Venda Futura!"
		#define STR0024 "Valor do veiculo divergente. Deseja atualizar valor de venda do veiculo no cadastro de ve�culos com o valor de venda deste atendimento?"
	#endif
#endif