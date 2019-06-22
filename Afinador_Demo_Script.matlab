classdef AFINADOR < matlab.apps.AppBase

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
        UIAxes                          matlab.ui.control.UIAxes
        UIAxes_3                        matlab.ui.control.UIAxes
        FUNDAMENTALGaugeLabel           matlab.ui.control.Label
        FUNDAMENTALGauge                matlab.ui.control.LinearGauge
        Lamp_2Label                     matlab.ui.control.Label
        Lamp_2                          matlab.ui.control.Lamp
    end

    properties (Access = private)       
        Fs;                   % Frecuencia de muestreo 
        recObj;               % Objeto del audio a recibir
        t; T; f; df;          % Variables para ejes temporal y frecuencial
        myRecording;          % Variable de audio a trabajar
        data; TF;             % Variables para graficar T. de Fourier
        maxpos; maxvalue; k;  % Variables de valor y posicion maxima en la TF
        e;                    % Error % entre ref y frecuencia de la nota
    end     

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Inicializando todas las variables
            app.Fs = 44100;
            app.Lamp.Color = [1 0 0]; 
            app.Lamp_2.Color = [1 0 0];
            app.Gauge.Value = 0;
            app.FUNDAMENTALGauge.Value = 0;
        end

        % Selection changed function: SELECTIVEMODEButtonGroup
        function SELECTIVEMODEButtonGroupSelectionChanged(app, event)
            selectedButton = app.SELECTIVEMODEButtonGroup.SelectedObject;
            switch selectedButton
                case app.MiButton                    
                    app.recObj = audiorecorder(app.Fs,8,1);         % Fs, nbits, nChannels
                    get(app.recObj);                    
                    recordblocking(app.recObj, 5);                  % Detener en x segundos
                    app.myRecording = getaudiodata(app.recObj);  
                    app.T=length(app.myRecording)/app.Fs;
                    app.t=linspace(0,app.T,app.T*app.Fs);           % Vector del eje de tiempo
                    plot(app.UIAxes,app.t,app.myRecording);
                    audiowrite('audio.wav',app.myRecording,app.Fs); % Guardar en archivo .wav

                    % Transformada de Fourier del audio 
                    [app.data app.Fs] = audioread('audio.wav');     % Obtener vector de datos del audio
                    app.TF = abs(fft(app.data)).^2;
                    app.df = 1/(length(app.data)/app.Fs);           % Intervalo de frecuencia
                    app.f = (0:length(app.data)-1)*app.df;          % Vector frecuencial
                    [app.maxvalue,app.k] = max(app.TF);             % Valor y posicion maximo de la potencia espectral
                    app.maxpos = app.f(app.k);                      % Frecuencia de la nota tocada
                    plot(app.UIAxes_3,app.f,app.TF);                    
                   
                    % Valor de maxpos en Linear Gauge
                    app.FUNDAMENTALGauge.Value = app.maxpos;
                                        
                    % Error con respecto a la frecuencia referencia
                    app.e = (app.maxpos-329.63)*100/329.63;         
                    app.Gauge.Value = app.e;
                    if app.Gauge.Value < -2
                        app.EditField.Value = 'Tune Up!';
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                    else
                        if app.Gauge.Value > 2
                        app.EditField.Value = 'Tune Down!'; 
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                        else 
                            app.EditField.Value = 'OK'; 
                            app.Lamp.Color = [0 1 0];
                            app.Lamp_2.Color = [0 1 0];
                        end
                    end  
                    
                case app.SIButton
                    app.recObj = audiorecorder(app.Fs,8,1);         % Fs, nbits, nChannels
                    get(app.recObj);                    
                    recordblocking(app.recObj, 5);                  % Detener en x segundos
                    app.myRecording = getaudiodata(app.recObj);  
                    app.T=length(app.myRecording)/app.Fs;
                    app.t=linspace(0,app.T,app.T*app.Fs);           % Vector del eje de tiempo
                    plot(app.UIAxes,app.t,app.myRecording);
                    audiowrite('audio.wav',app.myRecording,app.Fs); % Guardar en archivo .wav

                    % Transformada de Fourier del audio 
                    [app.data app.Fs] = audioread('audio.wav');     % Obtener vector de datos del audio
                    app.TF = abs(fft(app.data)).^2;
                    app.df = 1/(length(app.data)/app.Fs);           % Intervalo de frecuencia
                    app.f = (0:length(app.data)-1)*app.df;          % Vector frecuencial
                    [app.maxvalue,app.k] = max(app.TF);             % Valor y posicion maximo de la potencia espectral
                    app.maxpos = app.f(app.k);                      % Frecuencia de la nota tocada
                    plot(app.UIAxes_3,app.f,app.TF);
                    
                    % Valor de maxpos en Linear Gauge
                    app.FUNDAMENTALGauge.Value = app.maxpos;
                                        
                    % Error con respecto a la frecuencia referencia
                    app.e = (app.maxpos-246.94)*100/246.94;         
                    app.Gauge.Value = app.e;
                    if app.Gauge.Value < -2
                        app.EditField.Value = 'Tune Up!';
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                    else
                        if app.Gauge.Value > 2
                        app.EditField.Value = 'Tune Down!'; 
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                        else 
                            app.EditField.Value = 'OK'; 
                            app.Lamp.Color = [0 1 0];
                            app.Lamp_2.Color = [0 1 0];
                        end
                    end 
                    
                case app.SOLButton                    
                    app.recObj = audiorecorder(app.Fs,8,1);         % Fs, nbits, nChannels
                    get(app.recObj);                    
                    recordblocking(app.recObj, 5);                  % Detener en x segundos
                    app.myRecording = getaudiodata(app.recObj);  
                    app.T=length(app.myRecording)/app.Fs;
                    app.t=linspace(0,app.T,app.T*app.Fs);           % Vector del eje de tiempo
                    plot(app.UIAxes,app.t,app.myRecording);
                    audiowrite('audio.wav',app.myRecording,app.Fs); % Guardar en archivo .wav

                    % Transformada de Fourier del audio 
                    [app.data,app.Fs] = audioread('audio.wav');     % Obtener vector de datos del audio
                    app.TF = abs(fft(app.data)).^2;
                    app.df = 1/(length(app.data)/app.Fs);           % Intervalo de frecuencia
                    app.f = (0:length(app.data)-1)*app.df;          % Vector frecuencial
                    [app.maxvalue,app.k] = max(app.TF);             % Valor y posicion maximo de la potencia espectral
                    app.maxpos = app.f(app.k);                      % Frecuencia de la nota tocada
                    plot(app.UIAxes_3,app.f,app.TF);
                    
                    % Valor de maxpos en Linear Gauge
                    app.FUNDAMENTALGauge.Value = app.maxpos;
                                        
                    % Error con respecto a la frecuencia referencia
                    app.e = (app.maxpos-196)*100/196;         
                    app.Gauge.Value = app.e;
                    if app.Gauge.Value < -2
                        app.EditField.Value = 'Tune Up!';
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                    else
                        if app.Gauge.Value > 2
                        app.EditField.Value = 'Tune Down!'; 
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                        else 
                            app.EditField.Value = 'OK'; 
                            app.Lamp.Color = [0 1 0];
                            app.Lamp_2.Color = [0 1 0];
                        end
                    end
                    
                case app.REButton                    
                    app.recObj = audiorecorder(app.Fs,8,1);         % Fs, nbits, nChannels
                    get(app.recObj);                    
                    recordblocking(app.recObj, 5);                  % Detener en x segundos
                    app.myRecording = getaudiodata(app.recObj);  
                    app.T=length(app.myRecording)/app.Fs;
                    app.t=linspace(0,app.T,app.T*app.Fs);           % Vector del eje de tiempo
                    plot(app.UIAxes,app.t,app.myRecording);
                    audiowrite('audio.wav',app.myRecording,app.Fs); % Guardar en archivo .wav

                    % Transformada de Fourier del audio 
                    [app.data app.Fs] = audioread('audio.wav');     % Obtener vector de datos del audio
                    app.TF = abs(fft(app.data)).^2;
                    app.df = 1/(length(app.data)/app.Fs);           % Intervalo de frecuencia
                    app.f = (0:length(app.data)-1)*app.df;          % Vector frecuencial
                    [app.maxvalue,app.k] = max(app.TF);             % Valor y posicion maximo de la potencia espectral
                    app.maxpos = app.f(app.k);                      % Frecuencia de la nota tocada
                    plot(app.UIAxes_3,app.f,app.TF);
                    
                    % Valor de maxpos en Linear Gauge
                    app.FUNDAMENTALGauge.Value = app.maxpos;
                                        
                    % Error con respecto a la frecuencia referencia
                    app.e = (app.maxpos-146)*100/146;         
                    app.Gauge.Value = app.e;
                    if app.Gauge.Value < -2
                        app.EditField.Value = 'Tune Up!';
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                    else
                        if app.Gauge.Value > 2
                        app.EditField.Value = 'Tune Down!'; 
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                        else 
                            app.EditField.Value = 'OK'; 
                            app.Lamp.Color = [0 1 0];
                            app.Lamp_2.Color = [0 1 0];
                        end
                    end
                    
                case app.LAButton                    
                    app.recObj = audiorecorder(app.Fs,8,1);         % Fs, nbits, nChannels
                    get(app.recObj);                    
                    recordblocking(app.recObj, 5);                  % Detener en x segundos
                    app.myRecording = getaudiodata(app.recObj);  
                    app.T=length(app.myRecording)/app.Fs;
                    app.t=linspace(0,app.T,app.T*app.Fs);           % Vector del eje de tiempo
                    plot(app.UIAxes,app.t,app.myRecording);
                    audiowrite('audio.wav',app.myRecording,app.Fs); % Guardar en archivo .wav

                    % Transformada de Fourier del audio 
                    [app.data app.Fs] = audioread('audio.wav');     % Obtener vector de datos del audio
                    app.TF = abs(fft(app.data)).^2;
                    app.df = 1/(length(app.data)/app.Fs);           % Intervalo de frecuencia
                    app.f = (0:length(app.data)-1)*app.df;          % Vector frecuencial
                    [app.maxvalue,app.k] = max(app.TF);             % Valor y posicion maximo de la potencia espectral
                    app.maxpos = app.f(app.k);                      % Frecuencia de la nota tocada
                    plot(app.UIAxes_3,app.f,app.TF);
                    
                    % Valor de maxpos en Linear Gauge
                    app.FUNDAMENTALGauge.Value = app.maxpos;
                                       
                    % Error con respecto a la frecuencia referencia
                    app.e = (app.maxpos-110)*100/110;         
                    app.Gauge.Value = app.e;
                    if app.Gauge.Value < -2
                        app.EditField.Value = 'Tune Up!';
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                    else
                        if app.Gauge.Value > 2
                        app.EditField.Value = 'Tune Down!'; 
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                        else 
                            app.EditField.Value = 'OK'; 
                            app.Lamp.Color = [0 1 0];
                            app.Lamp_2.Color = [0 1 0];
                        end
                    end
                    
                case app.MIButton                    
                    app.recObj = audiorecorder(app.Fs,8,1);         % Fs, nbits, nChannels
                    get(app.recObj);                    
                    recordblocking(app.recObj, 5);                  % Detener en x segundos
                    app.myRecording = getaudiodata(app.recObj);  
                    app.T=length(app.myRecording)/app.Fs;
                    app.t=linspace(0,app.T,app.T*app.Fs);           % Vector del eje de tiempo
                    plot(app.UIAxes,app.t,app.myRecording);
                    audiowrite('audio.wav',app.myRecording,app.Fs); % Guardar en archivo .wav

                    % Transformada de Fourier del audio 
                    [app.data app.Fs] = audioread('audio.wav');     % Obtener vector de datos del audio
                    app.TF = abs(fft(app.data)).^2;
                    app.df = 1/(length(app.data)/app.Fs);           % Intervalo de frecuencia
                    app.f = (0:length(app.data)-1)*app.df;          % Vector frecuencial
                    [app.maxvalue,app.k] = max(app.TF);             % Valor y posicion maximo de la potencia espectral
                    app.maxpos = app.f(app.k);                      % Frecuencia de la nota tocada
                    plot(app.UIAxes_3,app.f,app.TF);
                    
                    % Valor de maxpos en Linear Gauge
                    app.FUNDAMENTALGauge.Value = app.maxpos;
                                        
                    % Error con respecto a la frecuencia referencia
                    app.e = (app.maxpos-164.81)*100/164.81;         
                    app.Gauge.Value = app.e;
                    if app.Gauge.Value < -2
                        app.EditField.Value = 'Tune Up!';
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                    else
                        if app.Gauge.Value > 2
                        app.EditField.Value = 'Tune Down!'; 
                        app.Lamp.Color = [1 0 0];
                        app.Lamp_2.Color = [1 0 0];
                        else 
                            app.EditField.Value = 'OK'; 
                            app.Lamp.Color = [0 1 0];
                            app.Lamp_2.Color = [0 1 0];
                        end
                    end    
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create EC3882PROYECTOSIITUNERUIFigure
            app.EC3882PROYECTOSIITUNERUIFigure = uifigure;
            app.EC3882PROYECTOSIITUNERUIFigure.Position = [100 100 544 355];
            app.EC3882PROYECTOSIITUNERUIFigure.Name = 'EC-3882 PROYECTOS II: TUNER';

            % Create AUDIO_TUNERPanel
            app.AUDIO_TUNERPanel = uipanel(app.EC3882PROYECTOSIITUNERUIFigure);
            app.AUDIO_TUNERPanel.Title = 'AUDIO_TUNER';
            app.AUDIO_TUNERPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.AUDIO_TUNERPanel.FontWeight = 'bold';
            app.AUDIO_TUNERPanel.Position = [14 12 520 330];

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
            app.MIButton.Value = true;

            % Create EditField
            app.EditField = uieditfield(app.AUDIO_TUNERPanel, 'text');
            app.EditField.HorizontalAlignment = 'center';
            app.EditField.Position = [290 21 83 22];

            % Create UIAxes
            app.UIAxes = uiaxes(app.AUDIO_TUNERPanel);
            title(app.UIAxes, 'ORIGINAL')
            app.UIAxes.Box = 'on';
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [9 161 257 137];

            % Create UIAxes_3
            app.UIAxes_3 = uiaxes(app.AUDIO_TUNERPanel);
            title(app.UIAxes_3, 'SPECTRUM')
            app.UIAxes_3.XLim = [0 500];
            app.UIAxes_3.ColorOrder = [0.6392 0.0784 0.1804;0.851 0.3255 0.098;0.9294 0.6941 0.1255;0.4941 0.1843 0.5569;0.4667 0.6745 0.1882;0.302 0.7451 0.9333;0.6353 0.0784 0.1843];
            app.UIAxes_3.Box = 'on';
            app.UIAxes_3.XGrid = 'on';
            app.UIAxes_3.YGrid = 'on';
            app.UIAxes_3.Position = [9 8 257 137];

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
            app.Lamp_2Label.Position = [460 161 25 15];
            app.Lamp_2Label.Text = '';

            % Create Lamp_2
            app.Lamp_2 = uilamp(app.AUDIO_TUNERPanel);
            app.Lamp_2.Position = [493 157 17 17];
        end
    end

    methods (Access = public)

        % Construct app
        function app = AFINADOR

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