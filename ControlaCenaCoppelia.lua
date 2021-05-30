-- This code is provided by Eric Rohmer
-- erohmer@gmail.com
-- you can use it without any warranty and modify reuse and distribute it at will

sim.setThreadSwitchTiming(2) -- Default timing for automatic thread switching
simDelegateChildScriptExecution()

-- Inicializacao de variaveis
novoModo = "m"
novaVeloc = 120
novoTempo = 100
tecla = "w"
estadoParado=0
direcao = "w"

--defining the serial parameters 
portNumber="\\\\.\\COM3" -- definindo a porta serial
baudrate=9600 -- definindo a velocidade de comunicacao pela porta (deve ser igual a do Arduino)
serial=sim.serialOpen(portNumber,baudrate) -- habilitando a porta serial

--getting the cube handle and initial pose

--ref = sim.getObjectHandle('Sphere')
h=sim.getObjectHandle('Cuboid')
refAbs = h
cam=sim.getObjectHandle('DefaultCamera')
ipos=sim.getObjectPosition(h,-1)
iori=sim.getObjectOrientation(h,-1)

xml = [[
<ui title="Controles Carro" closeable="false" resizable="false" activate="false">
    <group layout="form" flat="true">
        <label text="Velocidade: 120" id="1"/>
        <hslider tick-position="above" tick-interval="31" minimum="100" maximum="255" on-change="alteraVeloc" id="2"/>
        <label text="Tempo (ms): 100" id="3"/>
        <hslider tick-position="above" tick-interval="100" minimum="100" maximum="700" on-change="alteraTempo" id="4"/>
        <label text="Modo" id="5"/>
        <checkbox text="Automatico" on-change="alteraModo" checked="false" checkable="true" id="6"/>
        <label text="Movimento" id="7"/>
        <button text="PARAR" on-click="paradaEmergencia" checked="false" checkable="true" id="8"/>
        <label text="Sincronizar dados" id="9"/>
        <button text="SINCRONIZAR" on-click="enviaStringSerial" auto-repeat="true" auto-repeat-interval="1000" checkable="true" id="10"/>
    </group>
    <label text="" style="* {margin-left: 400px;}"/>
</ui>
]]
uiControle=simUI.create(xml)

xmlSensors = [[
<ui title="Acompanhamento Sensores" closeable="false" resizable="false" activate="false">
    <group layout="grid" flat="true">
        <label text="Esquerdo: 00.0 mm e Direito: 00.0 mm" id="1"/>
    </group>
    <label text="" style="* {margin-left: 300px;}"/>
</ui>
]]
uiSensors=simUI.create(xmlSensors)

--xmlAlerta = [[
--<ui title="Alerta de proximidade!" closeable="true" on-close="" resizable="false" activate="false">
    
--   <label text="Obstaculo Proximo!" id="1"/>
--    <label text="" style="* {margin-left: 300px;}"/>
--</ui>
--]]


function alteraVeloc(uiControle,id,newVal)
    novaVeloc = newVal
    simUI.setLabelText(uiControle,1,string.format("Velocidade: %i",novaVeloc))
end

function alteraTempo(uiControle,id,newVal)
    novoTempo = newVal
    simUI.setLabelText(uiControle,3,string.format("Tempo (ms): %i",novoTempo))
end

function alteraModo(uiControle,id,modoCB)
    -- estados 0 ou 2, desmarcado ou marcado respectivamente
    if modoCB==0 then
        novoModo = "m" -- Modo manual
        print(novoModo)
        enviaStringSerial()
    else
        novoModo = "k" -- Modo automatico
        print(novoModo)
        enviaStringSerial()
    end
end

function paradaEmergencia(uiControle,id,newVal)
    solicitaParada = estadoParado+1
    --print(newVal)
    if solicitaParada == 1 then
        tecla = 'q'
        enviaStringSerial()
        estadoParado = estadoParado+1
        simUI.setButtonText(uiControle,8,"PARADO")
    else
        estadoParado = 0
        solicitaParada = 0
        tecla = 'w'
        enviaStringSerial()
        simUI.setButtonText(uiControle,8,"MOVIMENTANDO")
    end
end

function andaDirecao(direcao) --religar simulacao
    if direcao == "w" then
        ipos[1] = ipos[1]+0.2;
        print("Ori Frente X",iori[1],", Y ",iori[2],", Z ",iori[3])
        sim.setObjectPosition(h,refAbs,{ipos[1],ipos[2],ipos[3]})
    elseif direcao == "s" then
        ipos[1] = ipos[1]-0.2;
        print("Ori Tras X",iori[1],", Y ",iori[2],", Z ",iori[3])
        sim.setObjectPosition(h,refAbs,{ipos[1],ipos[2],ipos[3]})
    elseif direcao == "a" then
        iori[3] = iori[3]+1.4*(math.pi/180);
        print("Ori Esquerda X",iori[1],", Y ",iori[2],", Z ",iori[3])
        sim.setObjectOrientation(h,refAbs,{iori[1],iori[2],iori[3]})
    elseif direcao == "d" then
        iori[3] = iori[3]-1.4*(math.pi/180);
        print("Ori Direita X",iori[1],", Y ",iori[2],", Z ",iori[3])
        sim.setObjectOrientation(h,refAbs,{iori[1],iori[2],iori[3]})
    end
end

function enviaStringSerial() -- criada funcao para fazer juncao e envio unico dos parametros
-- Envia uma string (texto)
    sim.serialSend(serial,string.format("%s,%i,%i,%s",novoModo,novaVeloc,novoTempo,tecla))
-- Mostra dentro do Status Bar do Coppelia a string enviada 
    print(string.format("Enviou %s,%i,%i,%s",novoModo,novaVeloc,novoTempo,tecla))
end

function imprimeVal()
    if val[3] ~= nil then
        print(string.format("Recebeu %s,%s,%s",val[1], val[2], val[3]))
    else
        print(string.format("Recebeu %s,%s,%s",val[1], val[2], "nil"))
    end
end

while (sim.getSimulationState()~=sim.simulation_advancing_abouttostop) do

    -- Aqui le-se uma linha a partir da Serial
    str=sim.serialRead(serial,100,true,'\r\n',100) -- armazena todo o texto em Str ate encontrar "\r\n"
    --print(str)
    if str ~= nil then -- Verifica se o valor recebido nao e vazio (nulo = nil)
        local token -- cria uma variavel apenas nesse contexto chamada token 
        val={} -- cria um vetor (array) para armazenar as informacoes que chegarem
        cpt=0 -- criou um contador para modificar as posicoes no vetor
        -- extraindo os valores na string Str separados por virgula
        for token in string.gmatch(str, "[^,]+") do -- para cada valor fora a virgula, sera salvo em token
            cpt=cpt+1 -- adiciona 1 para armazenar no proximo espaco do vetor
            val[cpt]= token -- armazena cada token em um espaco do vetor
        end
        val[1] = tonumber(val[1])
        val[2] = tonumber(val[2])
    end
    
    --imprimeVal()
    if val[3] ~= nil then
        direcao = val[3]
        andaDirecao(direcao)
    end
    
    -- Aqui mostra os valores dos sensores
    if (val[1]~= 0 and val[2]~= 0) then
        simUI.setLabelText(uiSensors,1,string.format("Sensor1: %.1f mm e Sensor2: %.1f mm",val[1], val[2]))
    end
    --if ((val[1]/10 <=120 or val[2]/10<=120) and (val[2]~= 0 and val[1]~=0)) then
    --    simUI.setLabelText(uiSensors,2,string.format("Objeto proximo!"))
    --end
    -- Codigo para ler mensagem e comandos do teclado
    message,auxiliaryData=sim.getSimulatorMessage()
	while message~=-1 do
		if (message==sim.message_keypress) then
			--print(auxiliaryData[1], ...)
			if (auxiliaryData[1]==string.byte('w')) then
                tecla = 'w'
                enviaStringSerial()
                --print('W')
                ipos[1] = ipos[1]+0.2;
                print("Ori Frente X",iori[1],", Y ",iori[2],", Z ",iori[3])
                sim.setObjectPosition(h,refAbs,{ipos[1],ipos[2],ipos[3]})
            elseif(auxiliaryData[1]==string.byte('s')) then
                tecla = 's'
                enviaStringSerial()
                --print('S')
                ipos[1] = ipos[1]-0.2;
                print("Ori Tras X",iori[1],", Y ",iori[2],", Z ",iori[3])
                sim.setObjectPosition(h,refAbs,{ipos[1],ipos[2],ipos[3]})
            elseif(auxiliaryData[1]==string.byte('a')) then
                tecla = 'a'
                enviaStringSerial()
                --print('A')
                iori[3] = iori[3]+1.4*(math.pi/180);
                print("Ori Esquerda X",iori[1],", Y ",iori[2],", Z ",iori[3])
                sim.setObjectOrientation(h,refAbs,{iori[1],iori[2],iori[3]})
            elseif(auxiliaryData[1]==string.byte('d')) then
                tecla = 'd'
                enviaStringSerial()
                --print('D')
                iori[3] = iori[3]-1.4*(math.pi/180);
                print("Ori Direita X",iori[1],", Y ",iori[2],", Z ",iori[3])
                sim.setObjectOrientation(h,refAbs,{iori[1],iori[2],iori[3]})
            elseif(auxiliaryData[1]==string.byte(' ')) then
                tecla = 'q'
                enviaStringSerial()
                print('PARAR')
                sim.serialSend(serial," ") -- codigo para parar
			end
		end
		message,auxiliaryData=sim.getSimulatorMessage()
	end

    -- not wasting time here, we force the switching of the thread
    sim.switchThread()
end

tecla = 'p'
enviaStringSerial()
print('FINALIZADO')

sim.serialClose(serial)
