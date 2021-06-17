sim.setThreadSwitchTiming(2) -- Default timing for automatic thread switching
simDelegateChildScriptExecution()

-- Put some initialization code here

-- definindo os parametros da serial
portNumber="\\\\.\\COM3" -- definindo a porta serial
baudrate=9600 -- definindo a velocidade de comunicacao pela porta (deve ser igual a do Arduino)
serial=sim.serialOpen(portNumber,baudrate) -- habilitando a porta serial

--Definindo os manipuladores (handle)
baseCarroRobo=sim.getObjectAssociatedWithScript(sim.handle_self) -- this is CarroRobo's handle
leftMotor=sim.getObjectHandle("CarroRobo_motorEsq") -- Handle of the left motor
rightMotor=sim.getObjectHandle("CarroRobo_motorDir") -- Handle of the right motor
leftSensor=sim.getObjectHandle("CarroRobo_sensorEsq") -- Handle of the left sensor
rightSensor=sim.getObjectHandle("CarroRobo_sensorDir") -- Handle of the right sensor
obstaculo = sim.getObjectHandle("Obstacle")
layer = sim.setObjectInt32Parameter(obstaculo,10,256)

-- Inicializacao de variaveis
novoModo = "m"
novaVeloc = 120
novoTempo = 100
tecla = "q"
estadoParado=0
direcao = "q"
contaPassos =0

-- Conversao de valor grau para radianos
minMaxVeloc={50*math.pi/180,135*math.pi/180} -- Min and max speeds for each motor (Em radianos/seg)
--print(minMaxVeloc[1],minMaxVeloc[2])

-- Create the custom UI:
    xml = '<ui title="Controle '..sim.getObjectName(baseCarroRobo)..'" closeable="false" resizeable="false" activate="false">'..[[
        <label text="Velocidade motores: 92.5 deg/s" id="1"/>
        <hslider minimum="0" maximum="100" on-change="velocChange_callback" id="2"/>
        <label text="Tempo (ms): 100" id="3"/>
        <hslider tick-position="above" tick-interval="100" minimum="100" maximum="700" on-change="alteraTempo" id="4"/>
        <label text="Modo" id="5"/>
        <checkbox text="Automatico" on-change="alteraModo" checked="false" checkable="true" id="6"/>
        <label text="Movimento" id="7"/>
        <button text="PARAR" on-click="paradaEmergencia" checked="false" checkable="true" id="8"/>
        <label text="Sincronizar dados" id="9"/>
        <button text="SINCRONIZAR" on-click="enviaStringSerial" auto-repeat="true" auto-repeat-interval="1000" checkable="true" id="10"/>
    <label text="" style="* {margin-left: 400px;}"/>
    </ui>
    ]]
uiControle=simUI.create(xml)

xmlSensors = [[
<ui title="Acompanhamento Sensores" closeable="false" resizable="false" activate="false">
        <label text="Esquerdo: 00.0 mm e Direito: 00.0 mm" id="1"/>
        <label text="" id="2"/>
    <label text="" style="* {margin-left: 300px;}"/>
</ui>
]]
uiSensors=simUI.create(xmlSensors)

veloc=(minMaxVeloc[1]+minMaxVeloc[2])*0.5
--print(veloc)
simUI.setSliderValue(uiControle,2,100*(veloc-minMaxVeloc[1])/(minMaxVeloc[2]-minMaxVeloc[1]))

function velocChange_callback(uiControle,id,newVal)
    veloc = minMaxVeloc[1]+((minMaxVeloc[2]-minMaxVeloc[1])*newVal/100)
    simUI.setLabelText(uiControle,1,string.format("Velocidade motores: %.1f deg/s",(veloc*180/math.pi)))
    novaVeloc = (veloc/math.pi)*255*1.3334 -- compensando a diferen?a de velociadade do carro virtual para o fisico
    andaDirecao()
    --print(novaVeloc)
end

function alteraTempo(uiControle,id,newVal)
    novoTempo = newVal
    simUI.setLabelText(uiControle,3,string.format("Tempo (ms): %i",novoTempo))
end

function alteraModo(uiControle,id,modoCB)
    -- estados 0 ou 2, desmarcado ou marcado respectivamente
    if modoCB==0 then
        novoModo = "m" -- Modo manual
        tecla = "q"
        direcao = tecla
        print(novoModo)
    else
        novoModo = "k" -- Modo automatico
        tecla = "w"
        print(novoModo)
    end
    andaDirecao()
    enviaStringSerial()
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


function andaDirecao() --religar simulacao
    if direcao == "w" or tecla == "w" then -- frente
        sim.setJointTargetVelocity(leftMotor,veloc) -- ao passar a velocidade para o motor, ela sera convertida para grau/seg
        sim.setJointTargetVelocity(rightMotor,veloc)
    elseif direcao == "s" or tecla == "s" then -- tras
        sim.setJointTargetVelocity(leftMotor,-veloc) -- ao passar a velocidade para o motor, ela sera convertida para grau/seg
        sim.setJointTargetVelocity(rightMotor,-veloc)
    elseif direcao == "a" or tecla == "a" then -- esquerda
        sim.setJointTargetVelocity(leftMotor,-veloc) -- ao passar a velocidade para o motor, ela sera convertida para grau/seg
        sim.setJointTargetVelocity(rightMotor,veloc)
    elseif direcao == "d" or tecla == "d" then -- direita
        sim.setJointTargetVelocity(leftMotor,veloc) -- ao passar a velocidade para o motor, ela sera convertida para grau/seg
        sim.setJointTargetVelocity(rightMotor,-veloc)
    elseif direcao == "q" or tecla == "q" then -- parar
        sim.setJointTargetVelocity(leftMotor,0) -- ao passar a velocidade para o motor, ela sera convertida para grau/seg
        sim.setJointTargetVelocity(rightMotor,0)
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


-- Put your main loop here, e.g.:
--
while sim.getSimulationState()~=sim.simulation_advancing_abouttostop do
    -- Aqui le-se uma linha a partir da Serial
    txtSerial=sim.serialRead(serial,100,true,'\r\n',100) -- armazena todo o texto em Str ate encontrar "\r\n"

    if txtSerial ~= nil then -- Verifica se o valor recebido nao e vazio (nulo = nil)
        local token -- cria uma variavel apenas nesse contexto chamada token 
        val={} -- cria um vetor (array) para armazenar as informacoes que chegarem
        cpt=0 -- criou um contador para modificar as posicoes no vetor
        -- extraindo os valores na txtSerialing txtSerial separados por virgula
        for token in string.gmatch(txtSerial, "[^,]+") do -- para cada valor fora a virgula, sera salvo em token
            cpt=cpt+1 -- adiciona 1 para armazenar no proximo espaco do vetor
            val[cpt]= token -- armazena cada token em um espaco do vetor
        end
        val[1] = tonumber(val[1]) --Leitura de ditancia do sensor ultrassonico da esquerda
        val[2] = tonumber(val[2]) --Leitura de ditancia do sensor ultrassonico da direita
    end
    
    --imprimeVal()
    if val[3] ~= nil and novoModo == "k" then
        direcao = val[3]
        tecla = direcao
        andaDirecao()
    end
    -- Valores dos sensores fisicos
    if (val[1]~= 0 and val[2]~= 0) then
        simUI.setLabelText(uiSensors,1,string.format("Sensor1: %.1f mm e Sensor2: %.1f mm",val[1], val[2]))
        if ((val[1] + val[2]) <= 260) or val[1]<=160 or val[2]<=160 then
            simUI.setLabelText(uiSensors,2,"OBJETO PROXIMO!")
            layer=sim.setObjectInt32Parameter(obstaculo,10,257)
        else
            simUI.setLabelText(uiSensors,2,"")
            layer=sim.setObjectInt32Parameter(obstaculo,10,256)
        end
    elseif (val[1]== 0) then
        simUI.setLabelText(uiSensors,1,string.format("Sensor1: %.1f mm e Sensor2: %.1f mm",0, val[2]))
        if val[2]<=160 and val[2]~=0 then
            simUI.setLabelText(uiSensors,2,"OBJETO PROXIMO!")
            layer=sim.setObjectInt32Parameter(obstaculo,10,257)
        else
            simUI.setLabelText(uiSensors,2,"")
            layer=sim.setObjectInt32Parameter(obstaculo,10,256)
        end
    elseif (val[2]== 0) then
        simUI.setLabelText(uiSensors,1,string.format("Sensor1: %.1f mm e Sensor2: %.1f mm",val[1], 0))
        if val[1]<=160 and val[1]~=0 then
            simUI.setLabelText(uiSensors,2,"OBJETO PROXIMO!")
            layer=sim.setObjectInt32Parameter(obstaculo,10,257)
        else
            simUI.setLabelText(uiSensors,2,"")
            layer=sim.setObjectInt32Parameter(obstaculo,10,256)
        end
    end
    
    -- Leitura dos sensores virtuais
    --res,dist=sim.readProximitySensor(ultrasonic)
    
    -- Direcoes pelo teclado
    message,auxiliaryData=sim.getSimulatorMessage()
    while message~=-1 do
        if (message==sim.message_keypress) then
            --print(auxiliaryData[1], ...)
            if (auxiliaryData[1]==string.byte('w')) then
                tecla = 'w'
                enviaStringSerial()
            elseif(auxiliaryData[1]==string.byte('s')) then
                tecla = 's'
                enviaStringSerial()
            elseif(auxiliaryData[1]==string.byte('a')) then
                tecla = 'a'
                enviaStringSerial()
            elseif(auxiliaryData[1]==string.byte('d')) then
                tecla = 'd'
                enviaStringSerial()
            elseif(auxiliaryData[1]==string.byte(' ')) then
                tecla = 'q'
                enviaStringSerial()
                print('PARAR')
            end
        end
        message,auxiliaryData=sim.getSimulatorMessage()
        andaDirecao()
    end
    
     sim.switchThread() -- resume in next simulation step
end


-- Put some clean-up code here
tecla = 'q'
enviaStringSerial()
andaDirecao()
print('FINALIZADO')

sim.serialClose(serial)
