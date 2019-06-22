classdef AFINADOR_SERIAL < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        EC3882PROYECTOSIITUNERUIFigure  matlab.ui.Figure
        AUDIO_TUNERPanel                matlab.ui.container.Panel
        Label                           matlab.ui.control.Label
        Lamp                            matlab.ui.control.Lamp
        GaugeLabel                      matlab.ui.control.Label
        Gauge                           matlab.ui.control.SemicircularGauge
        SELECTIVEMODEButtonGroup        matlab.ui.container.ButtonGroup
        MiButton                        matlab.ui.control.ToggleButton
        SIButton                        matlab.ui.control.ToggleButton
        SOLButton                       matlab.ui.control.ToggleButton
        REButton                        matlab.ui.control.ToggleButton
        LAButton                        matlab.ui.control.ToggleButton
        MIButton                        matlab.ui.control.ToggleButton
        EditField                       matlab.ui.control.EditField
        FUNDAMENTALGaugeLabel           matlab.ui.control.Label
        FUNDAMENTALGauge                matlab.ui.control.LinearGauge
        Lamp_2Label                     matlab.ui.control.Label
        Lamp_2                          matlab.ui.control.Lamp
        UIAxes2                         matlab.ui.control.UIAxes
        UIAxes1                         matlab.ui.control.UIAxes
    end

    properties (Access = private)       
        s;                    % Puerto serial COM_0
        valorADC;             % Datos de fread del puerto serial
        Fs;                   % Frecuencia de muestreo 
        w;                    % Vector frecuencia angular
        myAudio               % Variable de audio a trabajar
        TF,f,df;              % Variables para graficar T. de Fourier
        maxpos; maxvalue; k;  % Variables de valor y posicion maxima en la TF
        h1;                   % Objetos animated line
        data1,data2,data3;    % Variables de decodificacion
        data,vectordata       % Variable de datos 
        i,j;                  % Contador de datos
        x;                    % Tamaño de buffer
        frecREF;              % Valor de frecuencia de referencia de la nota
        e;                    % Error % entre ref y frecuencia de la nota
        amp;                  % Escalamiento segun codificacion
    end     

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Inicializando todas las variables
            app.Fs = 2000;
            app.amp = 65535;
            app.Lamp.Color = [1 0 0]; 
            app.Lamp_2.Color = [1 0 0];
            app.Gauge.Value = 0;
            app.FUNDAMENTALGauge.Value = 0;
            app.frecREF = 196;
            app.x = 365;                         
            app.vectordata = linspace(0,119,120);
            app.j = 1;
            
            % Inicializando puerto serial
            delete(instrfind(('port'),('COM7')));
            app.s = serial('COM7','BaudRate', 115200); % Mismo BaudRate del microcontrolador
            set(app.s,'InputBufferSize',365);          % Cualquier tamaño que abarque los 360 de la trama
            set(app.s,'Terminator','V');
            fopen(app.s);
            app.i = 0;                                 % Contador de datos
            app.myAudio = 0;
            
            % Creando objetos Animated Line
            app.h1 = animatedline(app.UIAxes1,'Color','b','LineStyle','-');
                        
            % DECODIFICACION 
            while(1)
              app.valorADC = fread(app.s,app.x,'uchar');              
              for v=1:3  
                if (app.valorADC(v) < 128)        % Condicion para 1er protocolo
                   for q = v:3:362+v              % Tamaño del buffer
                       app.j = q;
                       if (app.valorADC(v) > 63)  % Condicion para 2do protocolo
                           app.amp = 255;         % Escalamiento                  
                           app.data1 = 0;         % 1er byte no se usa en este caso                   
                       else    
                           app.amp = 65535;       % Escalamiento
                           app.data1 = bitshift(app.valorADC(app.j),10);
                       end                                             
                       app.data2 = bitshift(app.valorADC(app.j+1),4)-2048;                       
                       app.data3 = app.valorADC(app.j+2)-128;                       
                       app.data = (app.data1 + app.data2 + app.data3)*3; 
                       
                       app.data = app.data/app.amp; % Escalamiento                                                   
                       app.myAudio = app.data;      % Data de audio                
                       
                       % Asignar datos a la Animated Line y graficar
                       addpoints(app.h1,app.i,app.myAudio)
                       app.vectordata(app.i+1) = app.myAudio;
                       
                       % Contador de muestras 
                       app.i = app.i + 1;                                              
                   end
                   
                   % Transformada de Fourier del audio               
                   app.TF = abs(fft(app.vectordata)).^2;
                   app.TF(1) = 0;                         % Hacer Ao de TF 0                  
                   app.df = 1/(length(app.vectordata)/app.Fs);    
                   app.f = (0:length(app.vectordata)-1)*app.df;
                   [app.maxvalue,app.k] = max(app.TF);    % Valor y posicion maximo de la potencia espectral                               
                   app.maxpos = app.f(app.k);             % Frecuencia fund. de la nota tocada                   
                   
                   % Valor de maxpos en Linear Gauge
                   app.FUNDAMENTALGauge.Value = app.maxpos;
                   if app.FUNDAMENTALGauge.Value > 500
                       app.Lamp_2.Color = [1 0 0];                
                   end 
            
                   % Error con respecto a la frecuencia referencia:
                   % Se establece 5% o menor para considerar nota afinada               
                   app.e = (app.maxpos-app.frecREF)*100/app.frecREF;         
                   app.Gauge.Value = app.e;
                   if app.Gauge.Value < -5
                       app.EditField.Value = 'Tune Up!';
                       app.Lamp.Color = [1 0 0];
                       app.Lamp_2.Color = [1 0 0];
                   else
                       if app.Gauge.Value > 5
                           app.EditField.Value = 'Tune Down!'; 
                           app.Lamp.Color = [1 0 0];
                           app.Lamp_2.Color = [1 0 0];
                       else 
                           app.EditField.Value = 'OK'; 
                           app.Lamp.Color = [0 1 0];
                           app.Lamp_2.Color = [0 1 0];
                       end
                   end 
                
                   % Graficar data de audio y transformada de Fourier
                   drawnow                   
                   plot(app.UIAxes2,app.f,app.TF);
                
                   % Cuando llega al final del eje del display se resetea el contador y se hace flush al buffer                 
                   if app.i>=120               % Longitud del eje 
                       app.i = 0;              % Se resetea el contador de muestras              
                       clearpoints(app.h1);                                                   
                       flushinput(app.s);      % Se hace flush al buffer                   
                   end
                end   
              end 
            end                      
        end

        % Selection changed function: SELECTIVEMODEButtonGroup
        function SELECTIVEMODEButtonGroupSelectionChanged(app, event)
            selectedButton = app.SELECTIVEMODEButtonGroup.SelectedObject;
            switch selectedButton
                case app.MiButton
                    app.frecREF = 329.63;
                case app.SIButton
                    app.frecREF = 246.94;
                case app.SOLButton
                    app.frecREF = 196;
                case app.REButton
                    app.frecREF = 146;
                case app.LAButton
                    app.frecREF = 110;
                case app.MIButton
                    app.frecREF = 82.41;     
            end                                                                          
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create EC3882PROYECTOSIITUNERUIFigure
            app.EC3882PROYECTOSIITUNERUIFigure = uifigure;
            app.EC3882PROYECTOSIITUNERUIFigure.Position = [100 100 545 355];
            app.EC3882PROYECTOSIITUNERUIFigure.Name = 'EC-3882 PROYECTOS II: TUNER';

            % Create AUDIO_TUNERPanel
            app.AUDIO_TUNERPanel = uipanel(app.EC3882PROYECTOSIITUNERUIFigure);
            app.AUDIO_TUNERPanel.Title = 'AUDIO_TUNER';
            app.AUDIO_TUNERPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.AUDIO_TUNERPanel.FontWeight = 'bold';
            app.AUDIO_TUNERPanel.Position = [14 12 521 330];

            % Create Label
            app.Label = uilabel(app.AUDIO_TUNERPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [340 25 25 15];
            app.Label.Text = '';

            % Create Lamp
            app.Lamp = uilamp(app.AUDIO_TUNERPanel);
            app.Lamp.Position = [380 28 10 10];

            % Create GaugeLabel
            app.GaugeLabel = uilabel(app.AUDIO_TUNERPanel);
            app.GaugeLabel.HorizontalAlignment = 'center';
            app.GaugeLabel.Position = [326 42 25 15];
            app.GaugeLabel.Text = '';

            % Create Gauge
            app.Gauge = uigauge(app.AUDIO_TUNERPanel, 'semicircular');
            app.Gauge.Limits = [-12 12];
            app.Gauge.MajorTicks = [-12 -8 -4 0 4 8 12];
            app.Gauge.Position = [279 54 120 65];

            % Create SELECTIVEMODEButtonGroup
            app.SELECTIVEMODEButtonGroup = uibuttongroup(app.AUDIO_TUNERPanel);
            app.SELECTIVEMODEButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SELECTIVEMODEButtonGroupSelectionChanged, true);
            app.SELECTIVEMODEButtonGroup.TitlePosition = 'centertop';
            app.SELECTIVEMODEButtonGroup.Title = 'SELECTIVE MODE';
            app.SELECTIVEMODEButtonGroup.Position = [279 128 120 170];

            % Create MiButton
            app.MiButton = uitogglebutton(app.SELECTIVEMODEButtonGroup);
            app.MiButton.Text = 'Mi';
            app.MiButton.Position = [11 117 100 22];

            % Create SIButton
            app.SIButton = uitogglebutton(app.SELECTIVEMODEButtonGroup);
            app.SIButton.Text = 'SI';
            app.SIButton.Position = [11 96 100 22];

            % Create SOLButton
            app.SOLButton = uitogglebutton(app.SELECTIVEMODEButtonGroup);
            app.SOLButton.Text = 'SOL';
            app.SOLButton.Position = [11 75 100 22];
            app.SOLButton.Value = true;

            % Create REButton
            app.REButton = uitogglebutton(app.SELECTIVEMODEButtonGroup);
            app.REButton.Text = 'RE';
            app.REButton.Position = [11 54 100 22];

            % Create LAButton
            app.LAButton = uitogglebutton(app.SELECTIVEMODEButtonGroup);
            app.LAButton.Text = 'LA';
            app.LAButton.Position = [11 33 100 22];

            % Create MIButton
            app.MIButton = uitogglebutton(app.SELECTIVEMODEButtonGroup);
            app.MIButton.Text = 'MI';
            app.MIButton.Position = [11 12 100 22];

            % Create EditField
            app.EditField = uieditfield(app.AUDIO_TUNERPanel, 'text');
            app.EditField.Position = [290 21 83 22];

            % Create FUNDAMENTALGaugeLabel
            app.FUNDAMENTALGaugeLabel = uilabel(app.AUDIO_TUNERPanel);
            app.FUNDAMENTALGaugeLabel.HorizontalAlignment = 'center';
            app.FUNDAMENTALGaugeLabel.Position = [422 17 96 15];
            app.FUNDAMENTALGaugeLabel.Text = 'FUNDAMENTAL';

            % Create FUNDAMENTALGauge
            app.FUNDAMENTALGauge = uigauge(app.AUDIO_TUNERPanel, 'linear');
            app.FUNDAMENTALGauge.Limits = [0 500];
            app.FUNDAMENTALGauge.Orientation = 'vertical';
            app.FUNDAMENTALGauge.Position = [448 35 40 263];

            % Create Lamp_2Label
            app.Lamp_2Label = uilabel(app.AUDIO_TUNERPanel);
            app.Lamp_2Label.HorizontalAlignment = 'right';
            app.Lamp_2Label.Position = [460 158 25 15];
            app.Lamp_2Label.Text = '';

            % Create Lamp_2
            app.Lamp_2 = uilamp(app.AUDIO_TUNERPanel);
            app.Lamp_2.Position = [495 158 15 15];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.AUDIO_TUNERPanel);
            title(app.UIAxes2, 'SPECTRUM')
            app.UIAxes2.XLim = [0 500];
            app.UIAxes2.ColorOrder = [0.6392 0.0784 0.1804;0.851 0.3255 0.098;0.9294 0.6941 0.1255;0.4941 0.1843 0.5569;0.4667 0.6745 0.1882;0.302 0.7451 0.9333;0.6353 0.0784 0.1843];
            app.UIAxes2.Box = 'on';
            app.UIAxes2.XTick = [0 100 200 300 400 500];
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.Position = [21 17 234 134];

            % Create UIAxes1
            app.UIAxes1 = uiaxes(app.AUDIO_TUNERPanel);
            title(app.UIAxes1, 'ORIGINAL')
            app.UIAxes1.XLim = [0 120];
            app.UIAxes1.Box = 'on';
            app.UIAxes1.XTick = [0 20 40 60 80 100 120];
            app.UIAxes1.XTickLabel = {'0'; '20'; '40'; '60'; '80'; '100'; '120'};
            app.UIAxes1.XGrid = 'on';
            app.UIAxes1.YGrid = 'on';
            app.UIAxes1.Position = [21 158 234 134];
        end
    end

    methods (Access = public)

        % Construct app
        function app = AFINADOR_SERIAL

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.EC3882PROYECTOSIITUNERUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.EC3882PROYECTOSIITUNERUIFigure)
        end
    end
end