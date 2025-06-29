classdef HiLModelGenerationApp < matlab.apps.AppBase

    % Properties der App
    properties (Access = public)
        UIFigure                    matlab.ui.Figure

        NavPanel                    matlab.ui.container.Panel
        StepLabels                  (1,3) matlab.ui.control.Label

        Step1Panel                  matlab.ui.container.Panel
        SoIFinishedButton           matlab.ui.control.Button
        ContextTree                 matlab.ui.container.Tree
        SimulinkContextListBox      matlab.ui.control.ListBox
        SysMLPortTable              matlab.ui.control.Table
        SimulinkPortTable           matlab.ui.control.Table
        ContextInfoArea             matlab.ui.control.TextArea
        LabelLeft                   matlab.ui.control.Label
        LabelRight                   matlab.ui.control.Label

        Step2Panel                  matlab.ui.container.Panel
        ParameterFinishedButton     matlab.ui.control.Button
        BackButton                  matlab.ui.control.Button
        ContextParameterTable       matlab.ui.control.Table
        ResetToDefaultButton        matlab.ui.control.Button

        Step3Panel                  matlab.ui.container.Panel
        FidelityTree                matlab.ui.container.Tree
        DetailsPanel                matlab.ui.container.Panel
        HierachyFidelityPanel       matlab.ui.container.Panel
        EfficiencyModelFidelityPanel  matlab.ui.container.Panel
        DetailsTable                matlab.ui.control.Table
        ParameterTable              matlab.ui.control.Table
        EngModelsTable              matlab.ui.control.Table
        SimulationCheckBox          matlab.ui.control.CheckBox
        TestCheckBox                matlab.ui.control.CheckBox
        LowArchitecturalFidelityButton   matlab.ui.control.Button
        HighArchitecturalFidelityButton  matlab.ui.control.Button
        LowModelFidelityButton      matlab.ui.control.Button
        HighModelFidelityButton     matlab.ui.control.Button
        ModelGenerationButton       matlab.ui.control.Button
        EngModelDropDown            matlab.ui.control.DropDown
        
        dataStruct                  struct
        dataStructCutted            struct
        dataStructEdit              struct
        mainModelName               string  
        libraryName                 string
        dictionaryFileName          string
        powertrainName              string
        powertrainType              string
        contextModelName            string
        contextData
        
        greenModelStyle
        greenSubStyle
        greenTestStyle
        greenNoStyle
        yellowSubStyle
        yellowTestStyle
        yellowNoStyle
        redTestStyle
        redNoStyle
        
        standardTableStyle
        redMarkedTableStyle
        greenMarkedTableStyle

    end
    
    methods (Access = public)      % App-Initialisierung
        function app = HiLModelGenerationApp(jsonFileName)

            % find and close all open UIFigures
            f = findall(groot(),'Type','figure');
            for i = 1:numel(f)
                delete(f(i))
            end

            standardFileName = "Y:\MA\Matlab\JSON\Properties_Powertrain_eAxle2.json";

            % Wenn kein Argument oder 'null' übergeben wird, Standardpfad verwenden
            if nargin < 1 || isempty(jsonFileName) || strcmp(jsonFileName, 'null')
                jsonFileName = standardFileName;
                disp(['Kein gültiger Pfad übergeben. Standardpfad wird verwendet: ', jsonFileName]);
            else
                disp(['Übergebener Pfad: ', jsonFileName]);
            end

            % Datei laden und JSON-Inhalt in eine Struktur konvertieren
            try
                jsonData = fileread(jsonFileName);
                app.dataStruct = jsondecode(jsonData);
                disp(['JSON erfolgreich geladen: ', jsonFileName]);
            catch ME
                disp(['Fehler beim Laden der JSON-Datei: ', ME.message]);
                return;
            end

            % Name der benutzerdefinierten Bibliothek (customLibrary) festlegen
            app.libraryName = "HiL_Library";
            app.dictionaryFileName = "Library_Dictionary.sldd";

            % Laden und entsperren der Library
            if bdIsLoaded(app.libraryName)
                set_param(app.libraryName, 'Lock', 'off');
            else
                load_system(app.libraryName);
                pause(5);
                set_param(app.libraryName, 'Lock', 'off');
            end

            load(fullfile("ContextModels", "SimulinkContexts.mat"), "contextModels");
            app.contextData = contextModels;

            % Definition der UIStyles
            app.greenModelStyle = uistyle("FontColor", "black","FontWeight", "bold", "Icon", "success", "IconAlignment", "right");
            app.greenSubStyle = uistyle("FontColor", "black","FontWeight", "normal", "Icon", "success", "IconAlignment", "right");
            app.greenTestStyle = uistyle("FontColor", "blue","FontWeight", "bold", "Icon", "success", "IconAlignment", "right");
            app.greenNoStyle = uistyle("FontColor", "#B5B5B5","FontWeight", "normal", "Icon", "success", "IconAlignment", "right");
            app.yellowSubStyle = uistyle("FontColor", "black", "FontWeight", "normal", "Icon", "warning", "IconAlignment", "right");
            app.yellowTestStyle = uistyle("FontColor", "blue", "FontWeight", "bold", "Icon", "warning", "IconAlignment", "right");
            app.yellowNoStyle = uistyle("FontColor", "#B5B5B5", "FontWeight", "normal", "Icon", "warning", "IconAlignment", "right");
            app.redTestStyle = uistyle("FontColor", "blue", "FontWeight", "bold", "Icon", "error", "IconAlignment", "right");
            app.redNoStyle = uistyle("FontColor", "#B5B5B5", "FontWeight", "normal", "Icon", "error", "IconAlignment", "right");

            app.standardTableStyle = uistyle("FontWeight", "normal", "Icon", "none", "BackgroundColor", "white");
            app.redMarkedTableStyle = uistyle("FontWeight", "normal", "Icon", "none", "BackgroundColor", "red");
            app.greenMarkedTableStyle = uistyle("FontWeight", "normal", "Icon", "none", "BackgroundColor", "green");

            higthMain = 570;
            higthBottom = 100;
            widthNavPanel = 170;
            widthMain = 900;

            % Haupt-UI-Fenster erstellen
            app.UIFigure = uifigure( ...
                'Name', 'HiL-Model Generation App', ...
                'Position', [100, 100, widthNavPanel+widthMain+30, higthMain+20]);
            
            app.dataStructEdit = app.convertStruct(app.dataStruct);

            app.createNavPanel(higthMain, widthNavPanel);               % Navigationsbereich
            app.createPage1(higthMain, higthBottom, widthNavPanel, widthMain, contextModels);       % 1) Modell-Fidelity anpassen
            app.createPage2(higthMain, higthBottom, widthNavPanel, widthMain);       % 2) Modell-Fidelity anpassen
            app.createPage3(higthMain, higthBottom, widthNavPanel, widthMain);       % 3) Modell-Fidelity anpassen
          
            app.switchToStep(1);

        end

        function createNavPanel(app, higthMain, widthNavPanel)
            app.NavPanel = uipanel(app.UIFigure, ...
                'Title', 'Schritte', ...
                'BackgroundColor','white', ...
                'Position', [10 10 widthNavPanel higthMain]);
            
            stepTexts = { ...
                ['1) System of Interest', newline, 'und Kontext wählen'], ...
                ['2) Kontext-Parameter', newline, 'anpassen'], ...
                ['3) Modell-Fidelity', newline, 'anpassen']};

            for i = 1:3
                app.StepLabels(i) = uilabel(app.NavPanel, ...
                    'Text', stepTexts{i}, ...
                    'Position', [10, 470 - (i-1)*40, 160, 30], ...
                    'FontSize', 12, ...
                    'FontWeight', 'normal', ...
                    'FontColor', [0.5 0.5 0.5]);  % grau
            end
        end

        function createPage1(app, higthMain, higthBottom, widthNavPanel, widthMain, contexts)

            widthTable = 410;
            higthTable = 190;

            app.Step1Panel = uipanel(app.UIFigure, ...
                'Title', 'System of Interest wählen', ...
                'Position', [widthNavPanel+20 10 widthMain higthMain], ...
                'Visible', 'off');

            app.SoIFinishedButton = uibutton(app.Step1Panel, ...
                'Position', [widthMain-10-170, 10, 170, 70], ...
                'Text', 'Kontext passt so', ...
                'ButtonPushedFcn', @(src, event) app.step1Finished());

            app.ContextTree = uitree(app.Step1Panel, ...               % Tree erstellen
                'Position', [10, higthBottom+higthTable+10, widthTable, higthTable], ...
                'Multiselect', 'off', ...
                'SelectionChangedFcn', @(src, event) app.showPortsForSysML(event.SelectedNodes));

            contextNames = string({contexts.Name});
            app.SimulinkContextListBox = uilistbox(app.Step1Panel, ...
                'Position', [widthMain-10-widthTable, higthBottom+higthTable+10, widthTable/2-5, higthTable], ... % rechts neben Tree – anpassen je nach Layout
                'Items', contextNames, ...
                'ValueChangedFcn', @(src, event) app.showPortsAndDescriptionForSimulink(src), ...
                'Tag', 'SimulinkListBox');

           app.ContextInfoArea = uitextarea(app.Step1Panel, ...
                'Position', [widthMain-10-widthTable/2+5, higthBottom+higthTable+10, widthTable/2-5, higthTable], ...
                'Editable', 'off', ...
                'FontName', 'Helvetica', ...
                'FontSize', 12, ...
                'Value', ["SoI: ---", "Beschreibung: ---"]);

            app.SysMLPortTable = uitable(app.Step1Panel, ...
                'Position', [10, higthBottom, widthTable, higthTable], ...
                'ColumnName', {'Name', 'Type', 'Direction'}, ...
                'ColumnEditable', [false false false], ...
                'Tag', 'SysMLPortTable');

            app.SimulinkPortTable = uitable(app.Step1Panel, ...
                'Position', [widthMain-10-widthTable, higthBottom, widthTable, higthTable], ...
                'ColumnName', {'Name', 'Type', 'Direction'}, ...
                'ColumnEditable', [false false false], ...
                'Tag', 'SimulinkPortTable');

            app.LabelLeft = uilabel(app.Step1Panel, ...
                'Position', [10, higthBottom+2*higthTable+30, widthTable, 20], ...
                'Text', "SysML-Systemmodell", ...
                'FontSize', 14, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');

            app.LabelRight = uilabel(app.Step1Panel, ...
                'Position', [widthMain-10-widthTable, higthBottom+2*higthTable+30, widthTable, 20], ...
                'Text', "Simulink-Kontext-Modelle", ...
                'FontSize', 14, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');

            app.populateTree(app.ContextTree, app.dataStructEdit);
            app.checkPorts(app.ContextTree.Children(1), app.dataStruct);
            app.showPortsAndDescriptionForSimulink(app.SimulinkContextListBox)
        end

        function createPage2(app, higthMain, higthBottom, widthNavPanel, widthMain)
            app.Step2Panel = uipanel(app.UIFigure, ...
                'Title', 'Kontext-Parameter anpassen', ...
                'Position', [widthNavPanel+20 10 widthMain higthMain], ...
                'Visible', 'off');

            app.ParameterFinishedButton = uibutton(app.Step2Panel, ...
                'Position', [widthMain-10-170, 10, 170, 70], ...
                'Text', 'Parameter passen so', ...
                'ButtonPushedFcn', @(src, event) app.step2Finished());

            app.BackButton = uibutton(app.Step2Panel, ...
                'Position', [widthMain-10-170-90, 10, 80, 70], ...
                'Text', 'Zurück', ...
                'ButtonPushedFcn', @(src, event) app.switchToStep(1));

            app.ContextParameterTable = uitable(app.Step2Panel, ...
                'Position', [10, higthBottom+100, widthMain-20, 300], ...
                'ColumnName', {'Name', 'Subsystem', 'DefaultValue', 'Value', 'Unit'}, ...
                'ColumnEditable', [false false false true false], ...
                'Tag', 'ContextParameterTable');
            
            app.ResetToDefaultButton = uibutton(app.Step2Panel, ...
                'Text', "Standardwerte wiederherstellen", ...
                'Position', [10, higthBottom, 220, 30], ...
                'ButtonPushedFcn', @(btn, event) app.resetParametersToDefault());

        end

        function createPage3(app, higthMain, higthBottom, widthNavPanel, widthMain)
            app.Step3Panel = uipanel(app.UIFigure, ...
                'Title', 'Modell-Fidelity anpassen', ...
                'Position', [widthNavPanel+20 10 widthMain higthMain], ...
                'Visible', 'off');

            app.ModelGenerationButton = uibutton(app.Step3Panel, ...   % Button für den Export hinzufügen
                'Position', [widthMain-10-170, 10, 170, 70], ...
                'Text', 'Generate Simulink Model', ...
                'ButtonPushedFcn', @(src, event) app.simulinkModelGeneration());

            app.BackButton = uibutton(app.Step3Panel, ...
                'Position', [widthMain-10-170-90, 10, 80, 70], ...
                'Text', 'Zurück', ...
                'ButtonPushedFcn', @(src, event) app.switchToStep(2));


            app.FidelityTree = uitree(app.Step3Panel, ...               % Tree erstellen
                'Position', [10, 150, 280, 340], ...
                'Multiselect', 'off', ...
                'SelectionChangedFcn', @(src, event) app.updateDetailsPanel(event.SelectedNodes));
            
            tabGroup = uitabgroup(app.Step3Panel, ...
                "Position", [300, 150, 480, 340]);
            t1 = uitab(tabGroup, "Title", "Overview");
            t2 = uitab(tabGroup, "Title", "Parameters");
            t3 = uitab(tabGroup, "Title", "Efficiency Models");

            app.DetailsTable = uitable(t1, ...
                'Position', [10, 10, 460, 300], ...
                'ColumnName', {'Field', 'Value'}, ...
                'ColumnEditable', [false, false]);

            app.ParameterTable = uitable(t2, ...
                'Position', [10, 10, 460, 300], ...
                'ColumnName', {'Open Parameters', 'Value'}, ...
                'ColumnEditable', [false, false]);

            app.EngModelsTable = uitable(t3, ...
                'Position', [10, 160, 460, 150], ...
                'ColumnName', {'Fidelity', 'Model Name'}, ...
                'ColumnEditable', [false, false]);

            app.EngModelDropDown = uidropdown(t3, ...
                'Position', [200, 80, 150, 30], ...
                'Items', {'1', '2', '3', '4'}, ...
                'ValueChangedFcn', @(src, event) app.changeEtaModelFidelity(app.FidelityTree.SelectedNodes, src.Value));

            dropdownLabel = uilabel(t3, ...
                'Text', "Bitte Fidelity wählen:", ...
                'Position', [70, 80, 150, 30]);

            app.SimulationCheckBox = uicheckbox(app.Step3Panel, ...
                'Text', 'Simulation', ...
                'Position', [400 40 200 30], ...
                'ValueChangedFcn', @(src, event) app.changeSimulatedValue(app.FidelityTree.SelectedNodes, src.Value));

            app.TestCheckBox = uicheckbox(app.Step3Panel, ...
                'Text', 'Device under Test', ...
                'Position', [400 20 200 30], ...
                'ValueChangedFcn', @(src, event) app.changeDUT(app.FidelityTree.SelectedNodes, src.Value));

            app.HierachyFidelityPanel = uipanel(app.Step3Panel, ...
                "Title", "Architectural Fidelity", ...
                "TitlePosition", "centertop", ...
                "Position", [20, 20, 140, 110]);

            app.LowArchitecturalFidelityButton = uibutton(app.HierachyFidelityPanel, ...
                'Position', [10, 50, 120, 30], ...
                'Text', 'Lowest Fidelity', ...
                'ButtonPushedFcn', @(src, event) app.lowestFidelity(app.FidelityTree.Children(1)));

            app.HighArchitecturalFidelityButton = uibutton(app.HierachyFidelityPanel, ...
                'Position', [10, 10, 120, 30], ...
                'Text', 'Highest Fidelity', ...
                'ButtonPushedFcn', @(src, event) app.highestFidelity(app.FidelityTree.Children(1)));

            app.EfficiencyModelFidelityPanel = uipanel(app.Step3Panel, ...
                "Title", "Behavioral Fidelity", ...
                "TitlePosition", "centertop", ...
                "Position", [180, 20, 140, 110]);

            app.LowModelFidelityButton = uibutton(app.EfficiencyModelFidelityPanel, ...
                'Position', [10, 50, 120, 30], ...
                'Text', 'Lowest Fidelity', ...
                'ButtonPushedFcn', @(src, event) app.lowestFidelity(app.FidelityTree.Children(1)));

            app.HighModelFidelityButton = uibutton(app.EfficiencyModelFidelityPanel, ...
                'Position', [10, 10, 120, 30], ...
                'Text', 'Highest Fidelity', ...
                'ButtonPushedFcn', @(src, event) app.highestFidelity(app.FidelityTree.Children(1)));
        end

        function step1Finished(app)
            selectedNode = app.ContextTree.SelectedNodes;
            if isempty(selectedNode)
                uialert(app.UIFigure, "Bitte ein System auswählen!", "Fehlende Auswahl", "Icon", "warning");
                return;
            end
            delete(app.FidelityTree.Children);  % <--- Tree leeren

            rootName = selectedNode.Text;  % z. B. "Powertrain"
            app.dataStructCutted = app.cutSubstructToRoot(rootName, app.dataStruct);
            app.copySubtree(app.FidelityTree, selectedNode, "");

            app.checkPorts(app.FidelityTree.Children(1), app.dataStructCutted);
            if isempty(app.FidelityTree.Children)
                uialert(app.UIFigure, "Gewähltes SoI besitzt keine relevanten Ports!", "Schlechte Wahl", "Icon", "warning");
                return;
            end
            app.modelAnalysis(app.FidelityTree.Children(1));
            app.updateNodeAppearanceAll(app.FidelityTree.Children(1));

            % Page2
            selectedName = app.SimulinkContextListBox.Value;
            idx = find(string({app.contextData.Name}) == selectedName, 1);
            selectedContext = app.contextData(idx);
            params = selectedContext.Parameters;

            tableData = cell(length(params), 5);
            for i = 1:length(params)
                tableData{i, 1} = char(params(i).Name);
                tableData{i, 2} = char(params(i).Subsystem);
                tableData{i, 3} = params(i).DefaultValue;
                tableData{i, 4} = params(i).Value;
                tableData{i, 5} = char(params(i).Unit);
            end
            
            app.ContextParameterTable.Data = tableData;




            app.switchToStep(2);        % Wechsel zu Schritt 2
        end

        function step2Finished(app)

            % Kontextname aus ListBox in Page 1
            selectedName = app.SimulinkContextListBox.Value;
            idx = find(string({app.contextData.Name}) == selectedName, 1);
            selectedContext = app.contextData(idx);

            % Tabellendaten lesen
            tableData = app.ContextParameterTable.Data;
        
            % Alte Parameter holen
            params = app.contextData(idx).Parameters;
        
            % Neue Werte aus Spalte 4 ("Value") übernehmen
            for i = 1:min(size(tableData,1), length(params))
                params(i).Value = tableData{i, 4};
            end
        
            % Aktualisieren in contextData & selectedContext
            app.contextData(idx).Parameters = params;
            contextModels = app.contextData;
        
            % Optional: direkt speichern
            save(fullfile("ContextModels", "SimulinkContexts.mat"), "contextModels");
            assignin("base", "contextModels", app.contextData);
        
            disp("Parameter aktualisiert für: " + selectedName);
            app.switchToStep(3)
        end

        function switchToStep(app, step)
            % Alle Panels verbergen
            app.Step1Panel.Visible = 'off';
            app.Step2Panel.Visible = 'off';
            app.Step3Panel.Visible = 'off';
        
            % Nur gewünschten Schritt anzeigen
            switch step
                case 1
                    app.Step1Panel.Visible = 'on';
                case 2
                    app.Step2Panel.Visible = 'on';
                case 3
                    app.Step3Panel.Visible = 'on';
            end

            % Schrittanzeige visuell aktualisieren
            for i = 1:3
                if i == step
                    app.StepLabels(i).FontWeight = 'bold';
                    app.StepLabels(i).FontColor = [0 0 0];  % schwarz
                else
                    app.StepLabels(i).FontWeight = 'normal';
                    app.StepLabels(i).FontColor = [0.5 0.5 0.5];  % grau
                end
            end
        end

        function copySubtree(app, newParent, originalNode, currentPath)
            newNode = uitreenode(newParent);
            newNode.Text = originalNode.Text;
       
            % Pfad aufbauen
            if currentPath == ""
                newPath = originalNode.Text;
            else
                newPath = currentPath + "/" + originalNode.Text;
            end

            % NodeData kopieren & neuen Pfad setzen
            newNodeData = originalNode.NodeData;
            if isfield(newNodeData, "path")
                newNodeData.path = newPath;
            end
            newNode.NodeData = newNodeData;

            for i = 1:numel(originalNode.Children)
                app.copySubtree(newNode, originalNode.Children(i), newPath);  % Rekursion
            end
        end

        function showPortsForSysML(app, selectedNode)
            if isempty(selectedNode) || isempty(selectedNode.NodeData)
                app.SysMLPortTable.Data = {};
                return;
            end
        
            allPorts = struct("path", {}, "name", {}, "type", {}, "direction", {});

            if isfield(selectedNode.NodeData, "energyFlowPorts") && ~isempty(selectedNode.NodeData.energyFlowPorts)
                allPorts = [allPorts, selectedNode.NodeData.energyFlowPorts];
            end
            
            if isfield(selectedNode.NodeData, "signalFlowPorts") && ~isempty(selectedNode.NodeData.signalFlowPorts)
                allPorts = [allPorts, selectedNode.NodeData.signalFlowPorts];
            end
            
            % Sortieren nach Inputs und Outputs
            inPorts = allPorts(strcmp([allPorts.direction], "in"));
            outPorts = allPorts(strcmp([allPorts.direction], "out"));

            [~, idxIn] = sort([inPorts.name]);
            [~, idxOut] = sort([outPorts.name]);
            inPorts = inPorts(idxIn);
            outPorts = outPorts(idxOut);
            
            sortedPorts = [inPorts, outPorts];

            tableData = cell(length(sortedPorts), 3);  % 3 Spalten: Name, Type, Direction

            for i = 1:length(sortedPorts)
                tableData{i, 1} = char(sortedPorts(i).name);
                tableData{i, 2} = char(sortedPorts(i).type);
                tableData{i, 3} = char(sortedPorts(i).direction);
            end
            
            % Daten in Tabelle schreiben
            app.SysMLPortTable.Data = tableData;
        end

        function showPortsAndDescriptionForSimulink(app, listbox)
            selectedName = listbox.Value;

            % Kontext suchen
            idx = find(string({app.contextData.Name}) == selectedName, 1);
            if isempty(idx)
                app.SimulinkPortTable.Data = {};
                return;
            end
        
            selectedContext = app.contextData(idx);
        
            % Ports lesen
            ports = selectedContext.Ports;
        
            % Daten aufbereiten für Tabelle
            tableData = cell(length(ports), 3);
            for i = 1:length(ports)
                tableData{i, 1} = char(ports(i).Name);
                tableData{i, 2} = char(ports(i).Type);
                tableData{i, 3} = char(ports(i).Direction);
            end
            app.SimulinkPortTable.Data = tableData;

            soiText = selectedContext.SoI;
            description = selectedContext.Description;
            app.ContextInfoArea.Value = ["System of Interest:", "-> "+soiText, " ", "Description:", description];
            app.contextModelName = selectedContext.Name;

        end

        function resetParametersToDefault(app)
            % Kontext aus ListBox holen
            selectedName = app.SimulinkContextListBox.Value;
            idx = find(string({app.contextData.Name}) == selectedName, 1);
        
            % Zugriff auf Parameter
            params = app.contextData(idx).Parameters;
        
            % Tabellendaten aktualisieren: Default → Value
            for i = 1:length(params)
                params(i).Value = params(i).DefaultValue;
            end
        
            % In App speichern
            app.contextData(idx).Parameters = params;
        
            % Tabelle aktualisieren
            tableData = app.ContextParameterTable.Data;
            for i = 1:length(params)
                tableData{i, 4} = params(i).DefaultValue;  % Spalte "Value"
            end
            app.ContextParameterTable.Data = tableData;
        
            disp("Alle Werte wurden auf Standardwerte zurückgesetzt.");
        end

    end
    
    methods (Access = private) % Analysefunktionen
                
        function dataStructEdit = convertStruct(app, dataStruct, parentPath)
            
            if nargin < 3
                parentPath = "";
            end
            if parentPath == ""
                actualPath = string(dataStruct.Name);
            else
                actualPath = parentPath + "/" + string(dataStruct.Name);
            end

            % Hinzufügen von Einträgen auf aktueller Ebene
            dataStruct.name = string(dataStruct.Name);
            dataStruct.path = string(actualPath);
            dataStruct.type = string(dataStruct.Type);
            dataStruct.availability = "?";
            dataStruct.parameterExistance = "?";
            dataStruct.simulated = "no";
            dataStruct.switch = false;
            dataStruct.efficiencyModelFidelityChoice = '-';
           
            % Auslesen der enthaltenen Effizienz-Models
            efficiencyModels = struct("name", {}, "fidelity", {}, "engModelPath", {});
            if isfield(dataStruct, "EngineeringPurpose") && ~isempty(dataStruct.EngineeringPurpose)
                engPurposes = dataStruct.EngineeringPurpose;
                for k = 1:length(engPurposes)
                    engPurpose = engPurposes(k);
                    if startsWith(string(engPurpose.Purpose), "Efficiency")
                        if isfield(engPurpose, "EngineeringModels") && ~isempty(engPurpose.EngineeringModels)
                        engingeeringModels = engPurpose.EngineeringModels;
                            for m = 1:length(engingeeringModels)
                                engModel = engingeeringModels(m);
                                newEntry = struct("name", string(engModel.Name), "fidelity", string(num2str(engModel.Fidelity)), "engModelPath", string(engModel.ModelPath));
                                efficiencyModels(end + 1) = newEntry;
                            end
                        end
                    end
                end
            end

            % Sortierung mit aufsteigender Fidelity
            fidelityValues = arrayfun(@(x) x.fidelity, efficiencyModels);
            [~, sortIdx] = sort(fidelityValues);
            efficiencyModelsSorted = efficiencyModels(sortIdx);
            dataStruct.efficiencyModels = efficiencyModelsSorted; % Einfügen der sortieren efficiency Models
            if ~isempty(efficiencyModelsSorted)
                dataStruct.efficiencyModelFidelityChoice = num2str(efficiencyModelsSorted(1).fidelity);
            end

            % Auslesen der enthaltenen Parameter
            params = struct("name", {}, "value", {}, "unit", {});
            if isfield(dataStruct, "SystemParameters") && ~isempty(dataStruct.SystemParameters)
                parameters = dataStruct.SystemParameters;
                for j = 1:length(parameters)
                    parameter = parameters(j);
                    nameParts = split(parameter.Name, "/");
                    if strcmp(parameter.Unit, "Integer")
                        value = int16(str2double(parameter.Value));
                    elseif strcmp(parameter.Unit, "String")
                        value = string(parameter.Value);
                    else
                        value = double(str2double(parameter.Value));
                    end
                    newEntry = struct("name", string(nameParts{end}), "value", value, "unit", string(parameter.Unit));
                    params(end + 1) = newEntry;
                end
            end
            if isfield(dataStruct, "StructureSetParameters") && ~isempty(dataStruct.StructureSetParameters)
                parameters = dataStruct.StructureSetParameters;
                for j = 1:length(parameters)
                    parameter = parameters(j);
                    nameParts = split(parameter.Name, "/");
                    if strcmp(parameter.Unit, "Integer")
                        value = int16(str2double(parameter.Value));
                    elseif strcmp(parameter.Unit, "Real")
                        value = double(str2double(parameter.Value));
                    else
                        value = string(parameter.Value);
                    end
                    newEntry = struct("name", string(nameParts{end}), "value", value, "unit", string(parameter.Unit));
                    params(end + 1) = newEntry;
                end
            end
            dataStruct.params = params;

            dataStruct.openParams = struct("name", {}, "value", {});
            dataStruct.openEtaModel = string("-");
            
            % EnergyFlowPorts
            dataStruct.energyFlowPorts = struct("path", {}, "name", {}, "type", {},"direction", {});

            % SignalFlowPorts
            dataStruct.signalFlowPorts = struct("path", {}, "name", {}, "type", {}, "direction", {});

            

            % Rekursive Aufrufen für die darunter liegenden Ebenen
            if isfield(dataStruct, 'SystemSolutions')
                SystemSolutions = dataStruct.SystemSolutions;
                solutions = repmat(struct( ...
                    'name', [], ...
                    'path', [], ...
                    'type', [], ...
                    "availability", [], ...
                    'parameterExistance', [], ...
                    'simulated', [], ...
                    'switch', [], ...
                    'efficiencyModelFidelityChoice', [], ...
                    'efficiencyModels', [], ...
                    'params', [], ...
                    'openParams', [], ...
                    'openEtaModel', [], ...
                    'energyFlowPorts', [], ...
                    'signalFlowPorts', [], ...
                    'solutions', []), 1, length(SystemSolutions));                
                for i = 1:length(SystemSolutions)
                    solution = SystemSolutions(i);
                    convertedSolution = app.convertStruct(solution, dataStruct.path); % Rekursion aufrufen
                    solutions(i) = convertedSolution;
                end
                dataStruct.solutions = solutions;
            end

            % Löschen von alten Einträgen
            fieldsToRemove = {'EnergyFlowPorts', 'SignalFlowPorts', ...
                      'Connections', 'Name', 'Type', 'SolutionElements', 'SystemSolutions', ...
                      'EngineeringPurpose', 'SystemParameters', 'StructureElements', 'StructureSetParameters'};
            % vorher auch 'EngineeringConstraint'
            dataStruct = rmfield(dataStruct, fieldsToRemove);

            if isfield(dataStruct, 'ID')
                dataStruct = rmfield(dataStruct, 'ID');
            end

            dataStructEdit = dataStruct;



        end

        function populateTree(app, parentNode, currentDataStruct)
            
            subNode = uitreenode(parentNode);
            subNode.Text = currentDataStruct.name;
            subNode.NodeData = currentDataStruct; % Struct speichern

            if isfield(currentDataStruct, 'solutions') && ~isempty(currentDataStruct.solutions)
                solutions = currentDataStruct.solutions;
                for i = 1:length(solutions)
                    app.populateTree(subNode, solutions(i));
                end
            end
        end

        function checkPorts(app, currentNode, dataStruct)

            % rekursiver Aufruf für die Children
            if ~isempty(currentNode.Children)
                childNode = currentNode.Children;
                for i = 1:length(childNode)
                    app.checkPorts(childNode(i), dataStruct);
                end
            end

            % Raussuchen vom passenden Struct
            sysmlPath = currentNode.NodeData.path;
            simPath = app.simPathFromSysMLPath(sysmlPath);
            subsystemStruct = app.findStructBySysmlPath(sysmlPath, dataStruct);

            obsolete = true;

            % EnergyFlowPorts checken und zu TreeNode hinzufügen
            energyFlowPorts = struct("path", {}, "name", {}, "type", {},"direction", {});
            energyFlowPorts_old = subsystemStruct.EnergyFlowPorts;
            if isfield(subsystemStruct, "EnergyFlowPorts") && ~isempty(energyFlowPorts_old)
                for j = 1:length(energyFlowPorts_old)
                    energyFlowPort = energyFlowPorts_old(j);

                    if ~isfield(energyFlowPort, "Name") || ~isfield(energyFlowPort, "Type") || ~isfield(energyFlowPort, "Direction")
                        continue;
                    end
                    newEntry = struct( ...
                        "path", simPath, ...
                        "name", string(energyFlowPort.Name), ...
                        "type", string(energyFlowPort.Type), ...
                        "direction", string(energyFlowPort.Direction));
                    if strcmp(newEntry.type, "RotMechEnergyFlow") || strcmp(newEntry.type, "TranslMechEnergyFlow") || strcmp(newEntry.type, "ElectricEnergyFlow")
                        energyFlowPorts(end + 1) = newEntry;
                        obsolete = false;
                    end
                end
            end
            currentNode.NodeData.energyFlowPorts = energyFlowPorts;

            % SignalFlowPorts checken und zu TreeNode hinzufügen
            signalFlowPorts = struct("path", {}, "name", {}, "type", {}, "direction", {});
            signalFlowPorts_old = subsystemStruct.SignalFlowPorts;
            if isfield(subsystemStruct, "SignalFlowPorts") && ~isempty(signalFlowPorts_old)
                obsolete = false;
                for j = 1:length(signalFlowPorts_old)
                    signalFlowPort = signalFlowPorts_old(j);
                    newEntry = struct( ...
                        "path", simPath, ...
                        "name", string(signalFlowPort.Name), ...
                        "type", string(signalFlowPort.Type), ...
                        "direction", string(signalFlowPort.Direction));
                    signalFlowPorts(end + 1) = newEntry;
                end
            end
            currentNode.NodeData.signalFlowPorts = signalFlowPorts;

            if obsolete
%                 disp("SystemSolution ignoriert: " + sysmlPath)
                delete(currentNode); % Löschen des TreeNode, da irrelevant für Simulation
            end
        end

        function modelAnalysis(app, currentNode)
           
            allChildrenAvailable = false;

            % Start der Rekurstion mit der untersten Ebene
            if ~isempty(currentNode.Children)
                childNodes = currentNode.Children;
                for i = 1:length(childNodes)
                    childNode = childNodes(i);
                    app.modelAnalysis(childNode);
                    if ~strcmp(childNode.NodeData.availability, "Not available in Library!") && ...
                            ~strcmp(childNode.NodeData.availability, "Parameter missing!") && ...
                            ~strcmp(childNode.NodeData.availability, "EngModel missing!")
                        allChildrenAvailable = true;
                    end
                end
            end

%             disp("--- Verfügbare Blöcke in der Library:");
%             disp(find_system(app.libraryName, 'SearchDepth', 1, 'Name', 'PowerControlUnit_1Motor'));

            % Überprüft, ob der Block in der Library existiert
            availableInLibrary = ~isempty(find_system(app.libraryName, "SearchDepth", 1, "Name", currentNode.NodeData.type));

            if availableInLibrary
                pathInLibrary = app.libraryName + "/" + currentNode.NodeData.type;
                currentNode.NodeData.availability = pathInLibrary;
                [allParameterAvailable, allEngModelsAvailable] = app.checkParameter(currentNode);

                if allParameterAvailable && allEngModelsAvailable % Alle Test bestanden -> Grün
                    pathInLibrary = app.libraryName + "/" + currentNode.NodeData.type;
                    currentNode.NodeData.availability = pathInLibrary;
                elseif allChildrenAvailable % Tests nicht bestanden, aber submodels -> Gelb
                    currentNode.NodeData.availability = "Only Submodels available";
                else % Tests nicht bestanden -> Rot
                    if ~allParameterAvailable
                        currentNode.NodeData.availability = "Parameter missing!";
                    else
                        currentNode.NodeData.availability = "EngModel missing!";
                    end
                end

            elseif allChildrenAvailable % Modell nicht in Library aber Children verfügbar
                currentNode.NodeData.availability = "Only Submodels available";
            else % Ersten Test nicht bestanden -> Rot
                currentNode.NodeData.availability = "Not available in Library!";
            end


        end

        function [allParameterAvailable, allEngModelsAvailable] = checkParameter(app, currentNode)
           
            currentNode.NodeData.parameterExistance = "all Parameter exist";
            allParameterAvailable = true;
            allEngModelsAvailable = true;
          
            openParamsStruct = get_param(currentNode.NodeData.availability, "DialogParameters");
            if ~isempty(openParamsStruct) % Funktion nur relevant, wenn der Simulink-Block offene Parameter in Maske hat
                openParams = fieldnames(openParamsStruct);
                for j = 1:length(openParams)
                    openParam = string(openParams{j});
                    parts = split(openParam, "_");                  
                    part = string(parts{1});
      
                    % spezielleres Umgang für etaModels
                    if strcmp(openParam, "etaModel")
                        if ~isempty(currentNode.NodeData.efficiencyModels)
                            efficiencyModels = currentNode.NodeData.efficiencyModels;
                            for u = 1:length(efficiencyModels) % Suche nach dem aktuell ausgewählten Efficiency Model
                                efficiencyModel = efficiencyModels(u);
                                if strcmp(efficiencyModel.fidelity, currentNode.NodeData.efficiencyModelFidelityChoice)
                                    currentNode.NodeData.openEtaModel = efficiencyModel.engModelPath;
                                end
                            end
                        else
                            currentNode.NodeData.openEtaModel = "etaModel_is_missing";
                            allEngModelsAvailable = false;
                        end
%                         openParams(j) = []; % Löschen des Eintrages, damit etaModel nicht mehr als Parameter auftaucht
                        continue;
                    end

                    % Prüfen und Einfügen der restlichen offenen Parameter
                    value = [];
                    for z = 1:length(currentNode.NodeData.params)   % Durchsuchen der vorhandenen Parameter nach passendem Namen
                        if strcmp(openParam, currentNode.NodeData.params(z).name)
                            value = string(currentNode.NodeData.params(z).value);
                        end
                    end
                    if isempty(value)
                        value = "?";
                        currentNode.NodeData.parameterExistance = "Parameter missing!";
                        allParameterAvailable = false;
                    end
                    newEntry = struct("name", openParam, "value", value);
                    currentNode.NodeData.openParams(end + 1) = newEntry;                       
                end
            end
        end

        function updateDetailsPanel(app, selectedNode)

            app.DetailsTable.Data = {}; 
            if ~isempty(selectedNode) && ~isempty(selectedNode.NodeData)
                nodeData = selectedNode.NodeData;

                % Details Table
                fields = fieldnames(nodeData);
                values = struct2cell(nodeData);
        
                % Konvertiere Werte
                for i = 1:numel(values)
                    if isstring(values{i}) || ischar(values{i})
                        values{i} = char(values{i});
                    elseif isnumeric(values{i}) || islogical(values{i})
                        values{i} = num2str(values{i});
                    elseif isstruct(values{i})
                        values{i} = '<struct>';
                    else
                        values{i} = '<unsupported>';
                    end
                end
                
                % Daten anzeigen
                app.DetailsTable.Data = [fields, values];
                for i = 1:length(values)
                    if strcmp(values{i}, "Not available in Library!") || strcmp(values{i}, "Parameter missing!")
                        addStyle(app.DetailsTable, app.redMarkedTableStyle, "row", i);
                    else
                        addStyle(app.DetailsTable, app.standardTableStyle, "row", i);
                    end
                end

%                 app.SimulationCheckBox.Value = nodeData.switch;
                if strcmp(nodeData.simulated, "DUT")
                    app.TestCheckBox.Value = true;
                else
                    app.TestCheckBox.Value = false;
                end
                if strcmp(nodeData.simulated, "model")
                    app.SimulationCheckBox.Value = true;
                else
                    app.SimulationCheckBox.Value = false;
                end

                % Parameter extrahierne und Tabelle füllen
                nameColumn = arrayfun(@(x) x.name, nodeData.openParams(:), 'UniformOutput', true);
                valueColumn = arrayfun(@(x) x.value, nodeData.openParams(:), 'UniformOutput', false);
                app.ParameterTable.Data = [nameColumn, valueColumn];

                for i = 1:length(valueColumn)
                    if isstring(valueColumn{i}) && strcmp(valueColumn{i}, "?")
                        addStyle(app.ParameterTable, app.redMarkedTableStyle, "row", i);
                    else
                        addStyle(app.ParameterTable, app.standardTableStyle, "row", i);
                    end
                end

                % EfficiencyModels extrahieren und Tabelle füllen
                fidelityColumn = arrayfun(@(x) x.fidelity, nodeData.efficiencyModels(:), 'UniformOutput', false);
                modelPathColumn = arrayfun(@(x) x.engModelPath, nodeData.efficiencyModels(:), 'UniformOutput', true);
                app.EngModelsTable.Data = [fidelityColumn, modelPathColumn];

                charCellArray = cellfun(@num2str, fidelityColumn.', 'UniformOutput', false);
                app.EngModelDropDown.Items = charCellArray;  % Zuordnen der Liste der vorhandenen Modelle
                if ~isempty(charCellArray)
                    app.EngModelDropDown.Value = selectedNode.NodeData.efficiencyModelFidelityChoice; % aktualisieren des ausgewählten Eintrags
                end

                for i = 1:length(fidelityColumn) % Markierung des ausgewählten Modells
                    if strcmp(num2str(fidelityColumn{i}), selectedNode.NodeData.efficiencyModelFidelityChoice)
                        addStyle(app.EngModelsTable, app.greenMarkedTableStyle, "row", i);
                    else
                        addStyle(app.EngModelsTable, app.standardTableStyle, "row", i);
                    end
                end

            end
        end

        function updateNodeAppearance(app, node)
            if ~isempty(node) && isa(node, 'matlab.ui.container.TreeNode')

                if strcmp(node.NodeData.availability, "Not available in Library!") || ...
                    strcmp(node.NodeData.availability, "Parameter missing!") || ...
                    strcmp(node.NodeData.availability, "EngModel missing!")

                    if strcmp(node.NodeData.simulated, "DUT")
                        addStyle(app.FidelityTree, app.redTestStyle, "node", node);
                    elseif strcmp(node.NodeData.simulated, "no")
                        addStyle(app.FidelityTree, app.redNoStyle, "node", node);
                    else
                        error("Fehler in Modellauswahl - red");
                    end
                     
                elseif strcmp(node.NodeData.availability, "Only Submodels available")
                    if strcmp(node.NodeData.simulated, "subsystem")
                        addStyle(app.FidelityTree, app.yellowSubStyle, "node", node);
                    elseif strcmp(node.NodeData.simulated, "DUT")
                        addStyle(app.FidelityTree, app.yellowTestStyle, "node", node);
                    elseif strcmp(node.NodeData.simulated, "no")
                        addStyle(app.FidelityTree, app.yellowNoStyle, "node", node);
                    else
                        error("Fehler in Modellauswahl - yellow");
                    end

                else
                    if strcmp(node.NodeData.simulated, "model")
                        addStyle(app.FidelityTree, app.greenModelStyle, "node", node);
                    elseif strcmp(node.NodeData.simulated, "subsystem")
                        addStyle(app.FidelityTree, app.greenSubStyle, "node", node);
                    elseif strcmp(node.NodeData.simulated, "DUT")
                        addStyle(app.FidelityTree, app.greenTestStyle, "node", node);
                    elseif strcmp(node.NodeData.simulated, "no")
                        addStyle(app.FidelityTree, app.greenNoStyle, "node", node);
                    else
                        error("Fehler in Modellauswahl - green");
                    end
                end
            end
        end

        function updateNodeAppearanceAll(app, node)
            % Aktualisierung des aktuellen Knotens
            app.updateNodeAppearance(node);
    
            % Prüfen, ob der Knoten Kinder hat und diese ebenfalls aktualisieren
            if ~isempty(node.Children)
                for i = 1:length(node.Children)
                    app.updateNodeAppearanceAll(node.Children(i)); % Rekursiver Aufruf für jedes Kind
                end
            end
        end

    end



    methods (Access = private) % Modellauswahl
 
        function changeDUT(app, selectedNode, newValue)
            if newValue
                allSiblingsAvailable = app.checkAvailabilityChildren(selectedNode.Parent);
                noParentDUT = app.checkParentsForDUT(selectedNode);
                
                if ~allSiblingsAvailable
                    app.TestCheckBox.Value = false;
                    disp("Nicht genug Modelle verfügbar")

                elseif ~noParentDUT
                    app.TestCheckBox.Value = false;
                    disp(selectedNode.NodeData.name + " ist bereits under Test")
                else
                    selectedNode.NodeData.simulated = "DUT";
                    app.deactivateAllChildren(selectedNode);
                end
            else
                selectedNode.NodeData.simulated = "no";
            end

            
            app.updateDetailsPanel(selectedNode);  % Details-Panel aktualisieren
            app.updateNodeAppearanceAll(selectedNode);

%             app.updateDataStruct(selectedNode);  % Datenstruktur aktualisieren
        end

        function lowestFidelity(app, node)
            if strcmp(node.NodeData.simulated, "DUT")
            elseif strcmp(node.NodeData.availability, "Not available in Library!") || ...
                        strcmp(node.NodeData.availability, "Parameter missing!") || ...
                        strcmp(node.NodeData.availability, "EngModel missing!")
                disp("Fehler!!")
            elseif ~strcmp(node.NodeData.availability, "Only Submodels available") % Node grün
                node.NodeData.simulated = "model";
                app.deactivateAllChildren(node);
                app.updateNodeAppearanceAll(node)
            else % Node gelb
                node.NodeData.simulated = "subsystem";
                app.updateNodeAppearance(node);
                for i = 1:length(node.Children)
                    app.lowestFidelity(node.Children(i));
                end
            end
            app.updateDetailsPanel(node);  % Details-Panel aktualisieren
        end

        function highestFidelity(app, node)
            allChildrenAvailable = app.checkAvailabilityChildren(node);

            if strcmp(node.NodeData.simulated, "DUT")
            elseif strcmp(node.NodeData.availability, "Not available in Library!") || ...
                        strcmp(node.NodeData.availability, "Parameter missing!") || ...
                        strcmp(node.NodeData.availability, "EngModel missing!")
                disp("Fehler!!")

            elseif ~allChildrenAvailable % keine Children oder min ein Children rot
                node.NodeData.simulated = "model";
                app.deactivateAllChildren(node);
                app.updateNodeAppearanceAll(node)

            else % gelb oder grün
                node.NodeData.simulated = "subsystem";
                app.updateNodeAppearance(node);
                for i = 1:length(node.Children)
                    app.highestFidelity(node.Children(i));
                end
            end
        end
        
        function deactivateAllChildren(app, node)
            % Prüfen, ob Knoten Kinder hat
            if ~isempty(node.Children)
                for i = 1:length(node.Children)
                    childNode = node.Children(i);
                    if ~strcmp(childNode.NodeData.simulated, "DUT")
                        childNode.NodeData.simulated = "no";
                        childNode.NodeData.switch = false;
                        app.deactivateAllChildren(childNode);   % Rekursive Anwendung auf Unterknoten
%                         app.updateDataStruct(childNode);
                    end
                end
            end
        end

        function activateImmediateChildren(app, node)
            % Prüfen, ob der aktuelle Knoten untergeordnete Knoten hat
            if ~isempty(node.Children)
                for i = 1:length(node.Children)
                    childNode = node.Children(i);
                    if isfield(childNode.NodeData, 'simulated')
                        childNode.NodeData.simulated = "model";   % Simulated = 1 setzen
                        childNode.NodeData.switch = true;
                        app.updateDataStruct(childNode);
                    end
                end
            end
        end

        function deactivateAllParents(app, node)
            % Prüfen, ob der aktuelle Knoten einen Parent hat
            parentNode = node.Parent;
            if ~isempty(parentNode) && isprop(parentNode, 'NodeData') && ...
                    isfield(parentNode.NodeData, 'simulated') && isa(parentNode, 'matlab.ui.container.TreeNode')
                % Parent deaktivieren
                parentNode.NodeData.simulated = "subsystem";
                parentNode.NodeData.switch = false;
                app.updateDataStruct(parentNode);
    
                % Rekursive Anwendung: Parent des Parents deaktivieren
                app.deactivateAllParents(parentNode);
            end
        end

        function activateSiblings(app, node)
            if ~isempty(node) && isa(node, 'matlab.ui.container.TreeNode')
                % Prüfen, ob der aktuelle Knoten einen Parent hat
                parentNode = node.Parent;
                if ~isempty(parentNode) && numel(node.Parent.Children) > 1   % Prüfen, ob der Parent Siblings hat
                    for i = 1:length(parentNode.Children)
                        siblingNode = parentNode.Children(i);
                        if ~isequal(siblingNode, node)
                            app.activateNode(siblingNode)
                        end
                    end
                end
            end
        end

        function activateNode(app, currentNode)
            if ~isempty(currentNode.NodeData) && ...
                    isfield(currentNode.NodeData, 'simulated')
                if strcmp(currentNode.NodeData.availability, "Only Submodels available")
                    if ~isempty(currentNode) && numel(currentNode.Children) > 1
                        for y = 1:length(currentNode.Children)
                            childNode = currentNode.Children(y);
                            app.activateNode(childNode);
                        end
                        currentNode.NodeData.simulated = "subsystem";
                    end
                else
                    currentNode.NodeData.simulated = "model";
                    currentNode.NodeData.switch = true;
                    app.updateDataStruct(currentNode);
                end
            end
        end

        function updateDataStruct(app, node)
            % Rekursive Funktion, um den dataStruct-Baum zu aktualisieren
            function updatedStruct = updateStructElement(structNode, path, newSimulated, newSwitch)
                % Initialisieren der aktualisierten Struktur
                updatedStruct = structNode;
                
                % Wenn der Pfad übereinstimmt, Werte aktualisieren
                if strcmp(updatedStruct.path, path)
                    updatedStruct.simulated = newSimulated;
                    updatedStruct.switch = newSwitch;
                    
                elseif isfield(updatedStruct, 'solutions') && ~isempty(updatedStruct.solutions)
                    % Rekursives Suchen nach passendem Pfad in darunterliegenden Lösungen (Children)
                    for i = 1:length(updatedStruct.solutions)
                        updatedStruct.solutions(i) = updateStructElement(...
                            updatedStruct.solutions(i), path, newSimulated, newSwitch);
                    end
                end
            end
    
            % Start der Aktualisierung
            if ~isempty(node) && ~isempty(node.NodeData)
                app.dataStructEdit = updateStructElement(...
                    app.dataStructEdit, ...
                    node.NodeData.path, ...
                    node.NodeData.simulated, ...
                    node.NodeData.switch);
            end
        end

        function allChildrenAvailable = checkAvailabilityChildren(app, node)
            allChildrenAvailable = true;
            if ~isempty(node) && isa(node, 'matlab.ui.container.TreeNode')
                if isempty(node.Children)
                    allChildrenAvailable = false;
                    return;
                end
                for i = 1:length(node.Children)
                    child = node.Children(i);
                    if ~isequal(child, node) ...
                            && ~isempty(child.NodeData) && ...
                            isfield(child.NodeData, "availability")
                        if (strcmp(child.NodeData.availability, "Not available in Library!") || ...
                            strcmp(child.NodeData.availability, "Parameter missing!") || ...
                            strcmp(child.NodeData.availability, "EngModel missing!")) && ...
                            ~strcmp(child.NodeData.simulated, "DUT")
                        
                            allChildrenAvailable = false;
                            return;                    
                        end
                    end
                end
            end
        end

        function noParentDUT = checkParentsForDUT(app, node)
            noParentDUT = true;
            if isa(node.Parent, 'matlab.ui.container.TreeNode')
                if strcmp(node.Parent.NodeData.simulated, "DUT")
                    noParentDUT = false;
                    return;
                else
                    noParentDUT = app.checkParentsForDUT(node.Parent);
                end
            end
        end

        function changeSimulatedValue(app, selectedNode, newValue)
            if ~isempty(selectedNode) && ~isempty(selectedNode.NodeData)
   
                if newValue
                    allSiblingsAvailable = app.checkAvailabilityChildren(selectedNode.Parent);  % Check availability for sibllings
                    allParentsSiblingsAvailable = app.checkAvailabilityChildren(selectedNode.Parent.Parent); % Check availability for parents siblings
                    
                    if strcmp(selectedNode.NodeData.availability, "Not available in Library!") || ...
                        strcmp(selectedNode.NodeData.availability, "Only Submodels available") ||...
                        strcmp(selectedNode.NodeData.parameterExistance, "Parameter missing!") ||...
                        ~allSiblingsAvailable || ...
                        strcmp(allParentsSiblingsAvailable, "false")

                        uialert(app.UIFigure, 'Für mindestens ein Element ist kein entsprechendes HiL-Modell verfügbar oder Parameter fehlen.', 'Warnung');
                        app.SimulationCheckBox.Value = 0;
                        return;
                    else
                        selectedNode.NodeData.simulated = "model";
                        selectedNode.NodeData.switch = true;
                        app.deactivateAllChildren(selectedNode);
                        app.activateSiblings(selectedNode);
                        app.activateSiblings(selectedNode.Parent);
                        app.deactivateAllParents(selectedNode);
                        app.SimulationCheckBox.Value = 1;
                    end

                elseif ~newValue
                    allchildrenAvailable = app.checkAvailabilityChildren(selectedNode);
                    if isempty(selectedNode.Children)
                        uialert(app.UIFigure, 'Elemente ohne Teillösungen können nicht einzeln deaktiviert werden.', 'Warnung');
%                         app.SimulatedSwitch.Value = 'on';
                        app.SimulationCheckBox.Value = 1;
                        return;
                    elseif strcmp(allchildrenAvailable, "false")
                        uialert(app.UIFigure, 'Für mindestens ein Element ist kein entsprechendes HiL-Modell verfügbar oder Parameter fehlen.', 'Warnung');
%                         app.SimulatedSwitch.Value = 'on';
                        app.SimulationCheckBox.Value = 1;
                        return;
                    else
                        selectedNode.NodeData.simulated = "subsystem";
                        selectedNode.NodeData.switch = false;
                        app.SimulationCheckBox.Value = false;
                        app.activateImmediateChildren(selectedNode);   % Nur die direkte Ebene der Subnodes auf simulated = subsystem setzen
                    end
                end
    
                % Details-Panel aktualisieren
                app.updateDetailsPanel(selectedNode);

                % Datenstruktur aktualisieren
                app.updateDataStruct(selectedNode);

                % Stil des Knotens aktualisieren
                removeStyle(app.FidelityTree);    % Entferne bestehende Stile
                app.updateNodeAppearanceAll(app.FidelityTree.Children(1));
            else
                uialert(app.UIFigure, 'Bitte wählen Sie einen Knoten aus!', 'Warnung');
            end
        end

        function changeEtaModelFidelity(app, selectedNode, newValue)
            selectedNode.NodeData.efficiencyModelFidelityChoice = newValue;
            efficiencyModels = selectedNode.NodeData.efficiencyModels;                              
            for u = 1:length(efficiencyModels) % Suche nach dem aktuell ausgewählten Efficiency Model
                efficiencyModel = efficiencyModels(u);
                if strcmp(efficiencyModel.fidelity, selectedNode.NodeData.efficiencyModelFidelityChoice)
                    selectedNode.NodeData.openEtaModel = efficiencyModel.engModelPath;
                    continue;
                end
            end

            app.updateDetailsPanel(selectedNode)
        end
    end




    methods (Access = private) % Aggregation des Systems
        
        function [subsystems, libraryBlocks, testSystems] = modelPreparation(app, currentNode, dataStruct)
            subsystemPath = app.simPathFromSysMLPath(currentNode.NodeData.path);

            subsystems = struct( ...
                "path", {}, ...
                "name", {}, ...
                "type", {}, ...
                "elements", struct("path", {}, "name", {}, "type", {}), ...
                "energyFlowPorts", struct("path", {}, "name", {}, "type", {}, "direction", {}), ...
                "signalFlowPorts", struct("path", {}, "name", {}, "type", {}, "direction", {}), ...
                "energyConnections", struct("path", {}, "name", {}, "type", {}, "direction", {}), ...
                "signalConnections", struct("path", {}, "name", {}, "type", {}, "direction", {}));

            libraryBlocks = struct( ...
                "path", {}, ...
                "name", {}, ...
                "type", {}, ...
                "pathInLibrary", {}, ...
                "etaModelPath", string(""), ...
                "openParams", struct("name", {}, "value", {}));

            testSystems = struct( ...
                "path", {}, ...
                "name", {}, ...
                "type", {}, ...
                "elements", struct("path", {}, "name", {}, "type", {}), ...
                "energyFlowPorts", struct("path", {}, "name", {}, "type", {}, "direction", {}), ...
                "signalFlowPorts", struct("path", {}, "name", {}, "type", {}, "direction", {}), ...
                "energyConnections", struct("path", {}, "name", {}, "type", {}, "direction", {}), ...
                "signalConnections", struct("path", {}, "name", {}, "type", {}, "direction", {}));
            
            if strcmp(currentNode.NodeData.simulated, "subsystem")

                [energyConnections, signalConnections] = app.connectionPreparation(subsystemPath, dataStruct);
                newSubsystem = struct( ...
                    "path", subsystemPath, ...
                    "name", currentNode.NodeData.name, ...
                    "type", currentNode.NodeData.type, ...
                    "elements", struct("path", {}, "name", {}, "type", {}), ...
                    "energyFlowPorts", currentNode.NodeData.energyFlowPorts, "signalFlowPorts", currentNode.NodeData.signalFlowPorts, ...
                    "energyConnections", energyConnections, "signalConnections", signalConnections);
                solutions = currentNode.Children;
                if ~isempty(solutions)
                    for j = 1:length(solutions)
                        solutionInfo = solutions(j).NodeData;
                        newElement = struct("path", solutionInfo.path, "name", solutionInfo.name, "type", solutionInfo.type);
                        newSubsystem.elements(end + 1) = newElement;        
                    end
                end
                subsystems(end+1) = newSubsystem;
                
            elseif strcmp(currentNode.NodeData.simulated, "DUT")

                [energyConnections, signalConnections] = app.connectionPreparation(subsystemPath, dataStruct);
                newTestSystem = struct( ...
                    "path", subsystemPath, ...
                    "name", currentNode.NodeData.name, ...
                    "type", currentNode.NodeData.type, ...
                    "elements", struct("path", {}, "name", {}, "type", {}), ...
                    "energyFlowPorts", currentNode.NodeData.energyFlowPorts, "signalFlowPorts", currentNode.NodeData.signalFlowPorts, ...
                    "energyConnections", energyConnections, "signalConnections", signalConnections);
                solutions = currentNode.Children;
                if ~isempty(solutions)
                    for j = 1:length(solutions)
                        solutionInfo = solutions(j).NodeData;
                        newElement = struct("path", solutionInfo.path, "name", solutionInfo.name, "type", solutionInfo.type);
                        newTestSystem.elements(end + 1) = newElement;        
                    end
                end
                testSystems(end+1) = newTestSystem;
%                 testSystems(end + 1, 1) = subsystemPath;

            elseif strcmp(currentNode.NodeData.simulated, "model")
                newEntry = struct( ...
                    "path", subsystemPath, ...
                    "name", currentNode.NodeData.name, ...
                    "type", currentNode.NodeData.type, ...
                    "pathInLibrary", currentNode.NodeData.availability, ...
                    "etaModelPath", currentNode.NodeData.openEtaModel, ...
                    "openParams", currentNode.NodeData.openParams);
                libraryBlocks(end + 1) = newEntry;
            end

            % Rekursive Suche in Lösungen (Children)
            if ~isempty(currentNode.Children)
                for i = 1:length(currentNode.Children)
                    [nestedSubsystems, nestedLibraryBlocks, nestedTestSystems] = app.modelPreparation(currentNode.Children(i), dataStruct);
                    subsystems = [subsystems, nestedSubsystems];
                    libraryBlocks = [libraryBlocks, nestedLibraryBlocks];
                    testSystems = [testSystems, nestedTestSystems];
                end
            end
        end

        function [energyConnections, signalConnections] = connectionPreparation(app, subsystemPath, dataStruct)
            energyConnections = struct("srcPath", {}, "srcPortName", {}, "dstPath", {}, "dstPortName", {}, "actualSystem", {});
            signalConnections = struct("srcPath", {}, "srcPortName", {}, "dstPath", {}, "dstPortName", {}, "actualSystem", {});
        
            sysmlPath = SysmlPathFromSimPath(app, subsystemPath);
            subsystemStruct = app.findStructBySysmlPath(sysmlPath, dataStruct);

            % Energy- & Signal-Connections
            connections = subsystemStruct.Connections;
            if isfield(subsystemStruct, "Connections") && ~isempty(connections)
                for i = 1:size(connections,1)
                    connection = connections(i);

                    locationChar1 = connection.Ends(1).Name;
                    directionChar1 = string(connection.Ends(1).Direction);
                    locationChar2 = connection.Ends(2).Name;
                    directionChar2 = string(connection.Ends(2).Direction);

                    [blockPath1, portName1, portDirection1, portType1] = app.findSysmlPortForConnection(subsystemPath, subsystemStruct, locationChar1, directionChar1);
                    [blockPath2, portName2, portDirection2, portType2] = app.findSysmlPortForConnection(subsystemPath, subsystemStruct, locationChar2, directionChar2);
                    
                    if strcmp(portDirection1, "out") % auslesen der Portdirections und Entscheidung was src und was dst ist
                        newEntry = struct("srcPath", blockPath1, "srcPortName", portName1, "dstPath", blockPath2, "dstPortName", portName2, "actualSystem", subsystemPath);
                    else
                        newEntry = struct("srcPath", blockPath2, "srcPortName", portName2, "dstPath", blockPath1, "dstPortName", portName1, "actualSystem", subsystemPath);
                    end

                    if (strcmp(portType1, "RotMechEnergyFlow") && strcmp(portType2, "RotMechEnergyFlow")) || ...
                        (strcmp(portType1, "ElectricEnergyFlow") && strcmp(portType2, "ElectricEnergyFlow"))
                        energyConnections(end + 1) = newEntry;

                    else
                        if startsWith(portType1, "Signal") && startsWith(portType2, "Signal")
                            signalConnections(end + 1) = newEntry;
                        end
                    end
                end
                
            end
        end

        function [blockPath, portName, portDirection, portType] = findSysmlPortForConnection(app, path, subsystemStruct, locationChar, directionChar)
            char = split(locationChar, "/");
            
            if ~isempty(char{1})        % Port gehört zu normalem Block
                blockPath = "/"+ string(char{1});
                portName = string(char{2});
                portName_sysml = string(char{2});
                portDirection = directionChar;
                for m = 1:length(subsystemStruct.SystemSolutions) % Raussuchen des zugehörigen Structs für PortType
                    systemSolution = subsystemStruct.SystemSolutions(m);
                    if strcmp(string(systemSolution.Name), char{1})
                        break;
                    end
                end
                
            else            % Port gehört zu einem Port
                blockPath = string(locationChar);
                portName = "-";
                portName_sysml = string(char{2});
                systemSolution = subsystemStruct;
                if strcmp(directionChar, "in") % PortDirection muss einmal umgedreht werden
                    portDirection = "out";
                else
                    portDirection = "in";
                end
            end

            % Suche nach dem PortType in den Ports der zugehörigen Solution
            portType = "?";
            if ~isempty(systemSolution.EnergyFlowPorts) % Suche in EnergyFlowPorts
                for o = 1:length(systemSolution.EnergyFlowPorts)
                    energyPort = systemSolution.EnergyFlowPorts(o);
                    if strcmp(string(energyPort.Name), portName_sysml)
                        portType = string(energyPort.Type);
                        break;
                    end
                end
            end
            if strcmp(portType, "?") && ~isempty(systemSolution.SignalFlowPorts) % Suche in SignalFlowPorts
                for o = 1:length(systemSolution.SignalFlowPorts)
                    signalPort = systemSolution.SignalFlowPorts(o);
                    if strcmp(string(signalPort.Name), portName_sysml)
                        portType = string(signalPort.Type);
                        break;
                    end
                end
            end

        end

        function SimPath = simPathFromSysMLPath(app, SysMLPath)
            mainModelName = "MainModel";
            SimPath = mainModelName + "/" + SysMLPath;
        end

        function SysMLPath = SysmlPathFromSimPath(app, SimPath)
            prefix = app.mainModelName + "/";
            SysMLPath = extractAfter(SimPath, prefix);
        end
        
        function matchingStruct = findStructBySysmlPath(app, sysmlPath, dataStruct)
            matchingStruct = [];
            splitPath = split(sysmlPath, "/");
            
            % Error: Root Pfad passt nicht zusammen
            if ~strcmp(string(dataStruct.Name), splitPath{1})
%                 disp("Error: Root-Pfad passt nicht zusammen! - " + string(dataStruct.Name) +" ! "+ splitPath{1})
                return;
            end

            % Vollständiger Pfad abgearbeitet -> Treffer
            if length(splitPath) == 1
                matchingStruct = dataStruct;
                return;
            end

            % Rekursive Suche in den Unterstrukturen
            newPath = strjoin(splitPath(2:end), "/");
            for j = 1:length(dataStruct.SystemSolutions)
                solutionStruct = dataStruct.SystemSolutions(j);
                matchingStruct = findStructBySysmlPath(app, newPath, solutionStruct);
        
                if ~isempty(matchingStruct)
                    return;
                end
            end
        end
        
        function subStruct = cutSubstructToRoot(app, rootName, dataStruct)
            % Wenn Name übereinstimmt, gib den Struct direkt zurück
            if strcmp(dataStruct.Name, rootName)
                subStruct = dataStruct;
                return;
            end
        
            % Falls Children existieren, rekursiv weitersuchen
            if isfield(dataStruct, 'SystemSolutions')
                for i = 1:length(dataStruct.SystemSolutions)
                    candidate = dataStruct.SystemSolutions(i);
                    subStruct = app.cutSubstructToRoot(rootName, candidate);
                    if ~isempty(subStruct)
                        return;
                    end
                end
            end
        
            % Falls nichts gefunden wurde
            subStruct = [];
        end

        function matchingNode = findNodeBySysMLPath(app, currentNode, searchPath)
            
            matchingNode = [];  % Initialisierung
          
            if isfield(currentNode.NodeData, 'path') && strcmp(currentNode.NodeData.path, searchPath)
                matchingNode = currentNode;
            else
                childNodes = currentNode.Children;
                for i = 1:length(childNodes)
                    matchingNode = app.findNodeBySysMLPath(childNodes(i), searchPath);
                    if ~isempty(matchingNode)
                        break;
                    end
                end
            end
        end
      
        function portHandle = getEnergyPortHandle(app, blockPath, portName)
            % Initialisiere den Port-Handle
            portHandle = 0;
        
            % Hole die Port-Handles des Blocks
            portHandlesInfo = get_param(blockPath, "PortHandles");
            if strcmp(get_param(blockPath, "BlockType"), "PMIOPort")  % Falls Block selbst ein ConnectionPort ist
                portHandle = portHandlesInfo.RConn(1);
            else
                % Alle Verbindungsports durchsuchen und den gewünschten Port finden
                allPortHandles = [portHandlesInfo.LConn, portHandlesInfo.RConn];
                LConns = strings(0, 1);
                RConns = strings(0, 1);
                allConns = strings(0, 1);
                portList = find_system(blockPath, "FollowLinks", "on", "LookUnderMasks", "all", "SearchDepth", 1, "BlockType", "PMIOPort");
                for k = 1:length(portList)
                    portPath = string(portList{k});

                    side = string(get_param(portPath, "Side"));
                    if strcmp(side, "Left")
                        LConns = [LConns; portPath];
                    else
                        RConns = [RConns; portPath];
                    end
                end
                allConns = [LConns; RConns];
	            for l = 1:length(allConns)
                    if strcmp(allConns(l), blockPath + "/" + portName)
                        portHandle = allPortHandles(l);
                            break;
                    end
                end
            end
%             get_param(x, "ObjectParameters")
        end
        
        function portHandle = getSignalPortHandle(app, blockPath, portType, portName)
            % Initialisiere den Port-Handle
            portHandle = 0;
            portHandlesInfo = get_param(blockPath, "PortHandles");

            if strcmp(get_param(blockPath, "BlockType"), "Inport")  % Falls Block selbst ein Inport ist
                portHandle = portHandlesInfo.Outport(1);
            elseif strcmp(get_param(blockPath, "BlockType"), "Outport")  % Falls Block selbst ein Outport ist
                portHandle = portHandlesInfo.Inport(1);
            else  % Block ist sonstiger Block

                % Überprüfen, ob der gewünschte Port-Typ existiert und portHandle extrahieren   
                if strcmpi(portType, "out")
                    outportPathList = find_system(blockPath, "FollowLinks", "on", "LookUnderMasks", "all", "SearchDepth", 1, "BlockType", "Outport");
                    outportList = unique(get_param(outportPathList, "PortName"), "stable");  % stable sorgt dafür, dass nicht umsortiert wird
                    for k = 1:length(outportList)
                        if strcmp(outportList{k}, portName)
                            portHandle = portHandlesInfo.Outport(k);
                            break;
                        end
                    end
                elseif strcmpi(portType, "in")
                    inportPathList = find_system(blockPath, "FollowLinks", "on", "LookUnderMasks", "all", "SearchDepth", 1, "BlockType", "Inport");
                    inportList = unique(get_param(inportPathList, "PortName"), "stable");
                    for k = 1:length(inportList)
                        if strcmp(inportList{k}, portName)
                            portHandle = portHandlesInfo.Inport(k);
                            break;
                        end
                    end
                else
                    error("Ungültiger Port-Typ. Verwenden Sie in oder out.");
                end
            end

            if portHandle == 0
                error("SignalFlowPort von "+ blockPath +" "+ portName +" nicht gefunden.");
            end
        end
       
        function createAllBusElements(app, subsystems, testSystems, dictionaryFileName)

            % Dictionary-Datei laden und vorhandene Bus-Elemente in Base Workspace laden
            archDataObj = Simulink.data.dictionary.open(dictionaryFileName);
            section = getSection(archDataObj, "Design Data");
            allEntries = find(section);
            for k = 1:length(allEntries)
                entryName = allEntries(k).Name;
                entryValue = getValue(allEntries(k));
                if isa(entryValue, "Simulink.Bus")
                    assignin("base", entryName, entryValue);
                end
            end
            
            % Erstellung von neuem Bus-Element für jedes Subsystem
            for i = length(subsystems): -1:1
                subsystem = subsystems(i);
                mainBus = Simulink.Bus;
                busElements = [];
                for j = 1:length(subsystem.elements)
                    busElement = Simulink.BusElement;
                    busElement.Name = subsystem.elements(j).name;  % Name des Subsystems als Name im Bus
                    busElement.DataType = "Bus: Info_" + subsystem.elements(j).type;
                    busElements = [busElements, busElement];
                end
               
                energyFlowPorts = subsystem.energyFlowPorts;
                extraBusElements = app.createExtraBusElements(energyFlowPorts);
                busElements = [busElements, extraBusElements];

                mainBus.Elements = busElements;
                assignin("base", "Info_"+subsystem.type, mainBus);     % Das Bus-Objekt im Base Workspace speichern
                disp("Bus erstellt für: " + subsystem.path);           % Name des Bus entspricht Type der Solution
            end

            % Erstellung von neuem Bus-Element für jedes DUT
            for i = 1:length(testSystems)
                testBlock = testSystems(i);
                path = testBlock.path;
                busElements = [];

                energyFlowPorts = testBlock.energyFlowPorts;
                for k = 1:length(energyFlowPorts)
                    energyFlowPort = energyFlowPorts(k);

                    if strcmp(energyFlowPort.type, "RotMechEnergyFlow")
                        busElement = Simulink.BusElement;
                        busElement.Name = energyFlowPort.name;
                        busElement.DataType = "Bus: Info_RotMechEnergyFlow";
                        busElements = [busElements, busElement];

                    elseif strcmp(energyFlowPort.type, "TranslMechEnergyFlow")
                        busElement = Simulink.BusElement;
                        busElement.Name = energyFlowPort.name;
                        busElement.DataType = "Bus: Info_TranslMechEnergyFlow";
                        busElements = [busElements, busElement];

                    elseif strcmp(energyFlowPort.type, "ElectricEnergyFlow")
                        busElement = Simulink.BusElement;
                        busElement.Name = energyFlowPort.name;
                        busElement.DataType = "Bus: Info_ElectricEnergyFlow";
                        busElements = [busElements, busElement];
                    end
                end

                extraBusElements = app.createExtraBusElements(energyFlowPorts);
                busElements = [busElements, extraBusElements];

                testBus = Simulink.Bus;
                testBus.Elements = busElements;
                assignin("base", "DUT_Info_"+testBlock.type, testBus);
            end

        end

        function extraBusElements = createExtraBusElements(app, energyFlowPorts)

            extraBusElements = [];

            mechEnergyPorts_In = {};
            mechEnergyPorts_Out = {};
            rotMechEnergyPorts_Out = {};
            translMechEnergyPorts_Out = {};
            for k = 1:length(energyFlowPorts)
                energyFlowPort = energyFlowPorts(k);
                
                if strcmp(energyFlowPort.direction, "in")
                    if strcmp(energyFlowPort.type, "RotMechEnergyFlow") || strcmp(energyFlowPort.type, "TranslMechEnergyFlow")
                        mechEnergyPorts_In{end+1} = energyFlowPort.name;
                    end
                else
                    if strcmp(energyFlowPort.type, "RotMechEnergyFlow")
                        rotMechEnergyPorts_Out{end+1} = energyFlowPort.name;
                        mechEnergyPorts_Out{end+1} = energyFlowPort.name;
                    elseif strcmp(energyFlowPort.type, "TranslMechEnergyFlow")
                        translMechEnergyPorts_Out{end+1} = energyFlowPort.name;
                        mechEnergyPorts_Out{end+1} = energyFlowPort.name;
                    end
                end
            end

            % Buselemente für RotMechEnergyFlow Outports erstellen
            for i = 1:length(rotMechEnergyPorts_Out)
                busElement = Simulink.BusElement;
                busElement.Name = "J_red_" + rotMechEnergyPorts_Out{i};
                busElement.Unit = "kg*m^2";
                extraBusElements = [extraBusElements, busElement];
            end
            
            % Buselemente für TranslMechEnergyFlow Outports erstellen
            for i = 1:length(translMechEnergyPorts_Out)
                busElement = Simulink.BusElement;
                busElement.Name = "m_red_" + translMechEnergyPorts_Out{i};
                busElement.Unit = "kg";
                extraBusElements = [extraBusElements, busElement];
            end
            
            % Für jede Kombination von In- und Out-Ports eine Übersetzungszahl i_x_y erstellen
            for i = 1:length(mechEnergyPorts_In)
                for j = 1:length(mechEnergyPorts_Out)
                    busElement = Simulink.BusElement;
                    busElement.Name = "i_" + mechEnergyPorts_In{i} + "_" + mechEnergyPorts_Out{j};
                    extraBusElements = [extraBusElements, busElement];
                end
            end
        end


        %Aufbau des Modells
        function createEmptySubsystems(app, subsystems)
            for i = 1:length(subsystems)
                subsystem = subsystems(i);
                add_block("built-in/Subsystem", subsystem.path);
                add_block("simulink/Commonly Used Blocks/Out1", subsystem.path + "/Info", ...
                    OutDataTypeStr = "Bus: Info_"+subsystem.type);
                disp("Leeres Subsystem hinzugefügt: " + subsystem.path);
            end
        end

        function createTestBlocks(app, testSystems)
            for i = 1:length(testSystems)
                testBlock = testSystems(i);
                add_block("built-in/Subsystem", testBlock.path);
                disp("Test-Block hinzugefügt: " + testBlock.name);
            end
        end
        
        function createLibraryBlocks(app, libraryBlocks)
            for i = 1:length(libraryBlocks)
                libraryblock = libraryBlocks(i);
                add_block(libraryblock.pathInLibrary, libraryblock.path);
                disp("Modell aus Bibliothek hinzugefügt: " + libraryblock.pathInLibrary);
                
                if ~isempty(libraryblock.openParams)
                    for j = 1:length(libraryblock.openParams)
                        openParam = libraryblock.openParams(j);
                        set_param(libraryblock.path, openParam.name, openParam.value);
                    end
                end

                if ~strcmp(libraryblock.etaModelPath, "-")
                    set_param(libraryblock.path, "etaModel", ['''' char(libraryblock.etaModelPath) '''']);
                end
            end
        end
        
        function arrangeAllSubsystems(app, subsystems)
            % Für jedes Subsystem den Befehl arrangeSystem ausführen
            for i = 1:length(subsystems)    % Aufruf von arrangeSystem für jedes Subsystem
                subsystem = subsystems(i);
                Simulink.BlockDiagram.arrangeSystem(subsystem.path, FullLayout="true");
                disp("System arranged: " + subsystem.name);
            end
            Simulink.BlockDiagram.arrangeSystem(bdroot, FullLayout="true");
        end
        
        function createEnergyFlowPorts(app, subsystems, testSystems)
            bothSystems = [subsystems, testSystems];
            
            for k = 1:length(bothSystems)
                energyFlowPorts = bothSystems(k).energyFlowPorts;
                for j = 1:length(energyFlowPorts)
                    energyFlowPort = energyFlowPorts(j);
                    if strcmp(energyFlowPort.type, "RotMechEnergyFlow") || strcmp(energyFlowPort.type, "ElectricEnergyFlow")
                
                        %Setze die Ausrichtung des Ports basierend auf der "Direction"
                        if strcmp(energyFlowPort.direction, "out")
                            add_block("autolibsimscapeutils/Connection Port", energyFlowPort.path+"/"+energyFlowPort.name, ...
                                Side="Right", BlockMirror="on"); % Output für "out"-Ports
                            disp("Out-EnergyPort hinzugefügt: " + energyFlowPort.path);
                        else
                            add_block("autolibsimscapeutils/Connection Port", energyFlowPort.path+"/"+energyFlowPort.name, ...
                                Side="Left", BlockMirror="off"); % Input für "in"-Ports
                            disp("In-EnergyPort hinzugefügt: " + energyFlowPort.path);
                        end
                    end
                end
            end
        end

        function createSignalFlowPorts(app, subsystems, testSystems)
            bothSystems = [subsystems, testSystems];
            for k = 1:length(bothSystems)
                signalFlowPorts = bothSystems(k).signalFlowPorts;
                for j = 1:length(signalFlowPorts)
                    signalFlowPort = signalFlowPorts(j);
            
                    % Erstelle Ports basierend auf der "Direction"
                    if strcmp(signalFlowPort.direction, "in")
                        add_block("simulink/Commonly Used Blocks/In1", signalFlowPort.path+"/"+signalFlowPort.name, ...
                            OutDataTypeStr = "Bus: "+signalFlowPort.type);
                        disp("In-SignalFlowPort hinzugefügt: " + signalFlowPort.path);
                    else
                        add_block("simulink/Commonly Used Blocks/Out1", signalFlowPort.path+"/"+signalFlowPort.name, ...
                            OutDataTypeStr = "Bus: "+signalFlowPort.type);
                        disp("Out-SignalFlowPort hinzugefügt: " + signalFlowPort.path);
                    end
                end
            end
        end
        
        function createEnergyConnections(app, subsystems)
            for k = 1:length(subsystems)
                energyConnections = subsystems(k).energyConnections;
                for i = 1:length(energyConnections)
                    energyConnection = energyConnections(i);
                    srcPath = energyConnection.actualSystem+energyConnection.srcPath;
                    dstPath = energyConnection.actualSystem+energyConnection.dstPath;
            
                    srcPathExists = getSimulinkBlockHandle(srcPath) >0;
                    dstPathExists = getSimulinkBlockHandle(dstPath) >0;
                    
                    if srcPathExists && dstPathExists
	                    srcPortHandle = app.getEnergyPortHandle(srcPath, energyConnection.srcPortName);    % Prüfen, ob Out-Port existiert und geben Portnummer
                        dstPortHandle = app.getEnergyPortHandle(dstPath, energyConnection.dstPortName);    % Prüfen, ob In-Port existiert und geben Portnummer
                        % Verbindung erstellen
                        if (srcPortHandle >0 && dstPortHandle >0 )
                            add_line(energyConnection.actualSystem, srcPortHandle, dstPortHandle);              
                            disp("Energy-Verbindung hinzugefügt: " + srcPath + " -> " + dstPath);
                        else
                            disp("Warnung: Einer oder beide Ports existieren nicht: " + srcPath + " -> " + dstPath);
                        end
                    else
                        disp("Warnung: Einer oder beide Blocks existieren nicht: " + srcPath + " -> " + dstPath);
                    end
                end
            end
        end
        
        function createSignalConnections(app, subsystems)
            for k = 1:length(subsystems)
                signalConnections = subsystems(k).signalConnections;
                for i = 1:length(signalConnections)
                    signalConnection = signalConnections(i);
                    srcPath = signalConnection.actualSystem + signalConnection.srcPath;
                    dstPath = signalConnection.actualSystem + signalConnection.dstPath;
            
                    srcPathExists = getSimulinkBlockHandle(srcPath) >0;
                    dstPathExists = getSimulinkBlockHandle(dstPath) >0;
                    
                    if srcPathExists && dstPathExists
	                    srcPortHandle = app.getSignalPortHandle(srcPath, "out", signalConnection.srcPortName);    % Prüfen, ob Out-Port existiert und geben Portnummer
                        dstPortHandle = app.getSignalPortHandle(dstPath, "in", signalConnection.dstPortName);    % Prüfen, ob In-Port existiert und geben Portnummer
                        % Verbindung erstellen
                        if (srcPortHandle >0 && dstPortHandle >0 )
                            add_line(signalConnection.actualSystem, srcPortHandle, dstPortHandle);              
                            disp("Signal-Verbindung hinzugefügt: " + srcPath +"-"+ signalConnection.srcPortName + " -> " + dstPath + "-" + signalConnection.dstPortName);
                        else
                            disp("Warnung: Einer oder beide Ports existieren nicht: " + srcPath +"-"+ signalConnection.srcPortName + " -> " + dstPath + "-" + signalConnection.dstPortName);
                        end
                    else
                        disp("Warnung: Einer oder beide Blöcke existieren nicht: " + srcPath + " -> " + dstPath);
                    end
                end
            end
        end
        
        function createTestBlockAppliances(app, testSystems)
            for i = 1:length(testSystems)
                testBlock = testSystems(i);
                path = testBlock.path;

                add_block("simulink/Commonly Used Blocks/Out1", path+"/Info");
                add_block("built-in/Subsystem", path+"/Infos");
                add_block("simulink/Commonly Used Blocks/Out1", path+"/Infos/Info");
                add_line(path, "Infos/1", "Info/1");

                signalFlowPorts = testBlock.signalFlowPorts;
                for j = 1:length(signalFlowPorts)
                    signalFlowPort = signalFlowPorts(j);

                    busObj = evalin('base', signalFlowPort.type);
                    busElements = busObj.Elements;
                    elemNames = string(arrayfun(@(x) x.Name, busElements, 'UniformOutput', false));
                    commaSeparatedList = strjoin(elemNames, ',');

                    if strcmp(signalFlowPort.direction, "in")
                        add_block("simulink/Commonly Used Blocks/Bus Selector", path+"/HiL_"+signalFlowPort.name+"_Selector", ...
                            OutputSignals = commaSeparatedList);
                        add_line(path, signalFlowPort.name+"/1", "HiL_"+signalFlowPort.name+"_Selector/1");
                        for m = 1:length(elemNames)
                            add_block("simulink/Commonly Used Blocks/Terminator", path+"/HiL_"+signalFlowPort.name+"_"+elemNames(m));
                            add_line(path, "HiL_"+signalFlowPort.name+"_Selector/"+m, "HiL_"+signalFlowPort.name+"_"+elemNames(m)+"/1");
                        end
                    else
                        add_block("simulink/Commonly Used Blocks/Bus Creator", path+"/HiL_"+signalFlowPort.name+"_Creator", ...
                            OutDataTypeStr = "Bus: "+signalFlowPort.type, ...
                            InheritFromInputs='off', ...
                            Inputs = num2str(length(busElements)));
                        add_line(path, "HiL_"+signalFlowPort.name+"_Creator/1", signalFlowPort.name+"/1");
                        for m = 1:length(elemNames)
                            add_block("simulink/Commonly Used Blocks/Constant", path+"/HiL_"+signalFlowPort.name+"_"+elemNames(m));
                            add_line(path, "HiL_"+signalFlowPort.name+"_"+elemNames(m)+"/1", "HiL_"+signalFlowPort.name+"_Creator/"+m);
                        end
                    end
                end

                mechInPorts = [];
                mechOutPorts = [];

                energyFlowPorts = testBlock.energyFlowPorts;
                for k = 1:length(energyFlowPorts)
                    energyFlowPort = energyFlowPorts(k);
                    portName = energyFlowPort.name;
                    
                    add_block("simulink/Signal Routing/Two-Way Connection", path+"/"+portName+"_2WayConn");
                    add_line(path, ...
                        get_param(path+"/"+portName+"_2WayConn","PortHandles").RConn(1), ...
                        get_param(path+"/"+portName,"PortHandles").RConn(1));

                    if strcmp(energyFlowPort.type, "RotMechEnergyFlow")
                        busType = "Bus: Info_RotMechEnergyFlow";
                        busInputs = "M,omega";
                        input1 = "M";
                        input2 = "omega";
                    elseif strcmp(energyFlowPort.type, "TranslMechEnergyFlow")
                        busType = "Bus: Info_TranslMechEnergyFlow";
                        busInputs = "F,v";
                        input1 = "F";
                        input2 = "v";
                    elseif strcmp(energyFlowPort.type, "ElectricEnergyFlow")
                        busType = "Bus: Info_ElectricEnergyFlow";
                        busInputs = "P_el,x";
                        input1 = "P_el";
                        input2 = "x";
                    end

                    add_block("simulink/Commonly Used Blocks/Bus Creator", path+"/Infos/"+portName+"_EnergyBusCreator", ...
                        OutDataTypeStr = busType, ...
                        InheritFromInputs='off', ...
                        Inputs = busInputs);
                    add_block("simulink/Commonly Used Blocks/In1", path+"/Infos/"+portName+"_"+input1);
                    add_block("simulink/Commonly Used Blocks/In1", path+"/Infos/"+portName+"_"+input2);
                    add_line(path+"/Infos", portName+"_"+input1+"/1", portName+"_EnergyBusCreator/1");
                    add_line(path+"/Infos", portName+"_"+input2+"/1", portName+"_EnergyBusCreator/2");

                    if strcmp(energyFlowPort.direction, "in")
                        add_block("simulink/Commonly Used Blocks/Terminator", path+"/HiL_"+portName+"_"+input1);
                        add_line(path, portName+"_2WayConn/1", "HiL_"+portName+"_"+input1+"/1");
                        add_line(path, portName+"_2WayConn/1", "Infos/"+num2str(k*2-1));
                        add_block("simulink/Commonly Used Blocks/Constant", path+"/HiL_"+portName+"_"+input2);
                        add_line(path, "HiL_"+portName+"_"+input2+"/1", portName+"_2WayConn/1");
                        add_line(path, "HiL_"+portName+"_"+input2+"/1", "Infos/"+num2str(k*2));
                    else
                        add_block("simulink/Commonly Used Blocks/Constant", path+"/HiL_"+portName+"_"+input1);
                        add_line(path, "HiL_"+portName+"_"+input1+"/1", portName+"_2WayConn/1");
                        add_line(path, "HiL_"+portName+"_"+input1+"/1", "Infos/"+num2str(k*2-1));
                        add_block("simulink/Commonly Used Blocks/Terminator", path+"/HiL_"+portName+"_"+input2);
                        add_line(path, portName+"_2WayConn/1", "HiL_"+portName+"_"+input2+"/1");
                        add_line(path, portName+"_2WayConn/1", "Infos/"+num2str(k*2));
                    end

                    if strcmp(energyFlowPort.type, "RotMechEnergyFlow") || strcmp(energyFlowPort.type, "TranslMechEnergyFlow")
                        if strcmp(energyFlowPort.direction, "in")
                            mechInPorts = [mechInPorts, energyFlowPort];
                        else
                            mechOutPorts = [mechOutPorts, energyFlowPort];
                        end
                    end

                end
                           
                % Zusammenführen der Informationen zu Info-Output
                busType = ['DUT_Info_', char(testBlock.type)];
                busObj = evalin('base', busType);
                busElements = busObj.Elements;
                elemNames = string(arrayfun(@(x) x.Name, busElements, 'UniformOutput', false));

                add_block("simulink/Signal Routing/Bus Creator", path + "/Infos/InfoBusCreator", ...
                    OutDataTypeStr="Bus: DUT_Info_"+ testBlock.type, ...
                    InheritFromInputs='off', ...
                    Inputs = num2str(length(busElements)));
                add_line(path+"/Infos", "InfoBusCreator/1", "Info/1");

                % Dummy: Erstellen der Massenträgheitsmomente und Übersetzungszahlen
                for i = 1:length(elemNames)
                    blockName = elemNames(i);
                    if startsWith(blockName, "J_red")
                        add_block("simulink/Sources/Constant", path + "/Infos/"+blockName, Value="0");   % Constant-Block hinzufügen
                        add_line(path+"/Infos", blockName+"/1", "InfoBusCreator/"+i);

                    elseif startsWith(blockName, "i")  % Prüfen, ob der Name mit "i" beginnt
                        if strcmp(blockName, "i")
                            inName = mechInPorts(1).name;
                            outName = mechOutPorts(1).name;
                            blockNameFull = "i_" + inName + "_" + outName;
                        else
                            for m = 1:length(mechInPorts)
                                for n = 1:length(mechOutPorts)
                                    testName = "i_"+mechInPorts(m).name+"_"+mechOutPorts(n).name;
                                    if strcmp(testName, blockName)
                                        blockNameFull = blockName;
                                        inName = mechInPorts(m).name;
                                        outName = mechOutPorts(n).name;
                                    end
                                end
                            end
                        end

                        % Division: omega_in / omega_out
                        add_block("simulink/Math Operations/Divide", path+"/Infos/"+blockNameFull+"_div");
                        add_line(path+"/Infos", inName + "_omega/1", blockNameFull + "_div/1");
                        add_line(path+"/Infos", outName + "_omega/1", blockNameFull + "_div/2");
                        add_line(path+"/Infos", blockNameFull+"_div/1", "InfoBusCreator/"+i);
       
                    else
                        add_line(path+"/Infos", blockName+"_EnergyBusCreator/1", "InfoBusCreator/"+i);  % Weiterleitung von EnergyBusCreator an InfoBus
                    end
                end

                Simulink.BlockDiagram.arrangeSystem(path+"/Infos", FullLayout="true");
                Simulink.BlockDiagram.arrangeSystem(path, FullLayout="true");
            end
        end

        function createInfoOutputs(app, subsystems)
            for i = length(subsystems): -1:1
                subsystem = subsystems(i);
                gotoCount = 1;

                % Create Infos Subsystem
                add_block("built-in/Subsystem", subsystem.path+"/Infos")
%                 add_block("simulink/Commonly Used Blocks/Out1", subsystem.path + "/Info");
                add_block("simulink/Commonly Used Blocks/Out1", subsystem.path + "/Infos/"+subsystem.name, ...
                    OutDataTypeStr = "Bus: Info_"+subsystem.type);

                busName = ['Info_', char(subsystem.type)];
                busObj = evalin('base', busName);
                busElements = busObj.Elements;
                elemNames = string(arrayfun(@(x) x.Name, busElements, 'UniformOutput', false));

                add_block("simulink/Signal Routing/Bus Creator", subsystem.path + "/Infos/BusCreator", ...
                    OutDataTypeStr="Bus: Info_"+ subsystem.type, ...
                    InheritFromInputs='off', ...
                    Inputs = num2str(length(busElements)));
                add_line(subsystem.path+"/Infos", "BusCreator/1", subsystem.name+"/1");


                % Erstellen der Massenträgheitsmomente und Übersetzungszahlen
                sysMLPath = app.SysmlPathFromSimPath(subsystem.path);
                currentNode = app.findNodeBySysMLPath(app.FidelityTree.Children(1), sysMLPath);
                              
                for i = 1:length(elemNames)  % Durchgehen aller BusElements
                    elemName = elemNames(i);

                    if startsWith(elemName, "J_red")  % Prüfen, ob der Name mit "J_red" oder "i" beginnt
%                         add_block("simulink/Sources/Constant", subsystem.path + "/Infos/"+elemName);   % Constant-Block hinzufügen
                        app.calculateInertia(elemName, subsystem, currentNode);

                    elseif startsWith(elemName, "i")
                        app.calculateGearRatio(elemName, subsystem, currentNode);
                    
                    else
                        % Elemente in Infos-Block
                        add_block("simulink/Commonly Used Blocks/In1", subsystem.path + "/Infos/"+elemName); % Input-Block in Infos
        
                        % Verbindungen auf Hauptebenen zu Infos-Block
                        gotoTag = ["Info_"+num2str(gotoCount)];
                        gotoBlock = add_block('simulink/Signal Routing/Goto', subsystem.path +"/"+ gotoTag, ...
                            'GotoTag', gotoTag, ...
                            "Position", [0 0 20 10]);
                        add_line(subsystem.path, elemName+ "/1",  gotoTag+"/1");
    
                        fromBlock = add_block('simulink/Signal Routing/From', subsystem.path +"/From_"+ num2str(gotoCount), ...
                            'GotoTag', gotoTag, ...
                            "Position", [0 0 20 10]);
                        add_line(subsystem.path,"From_"+ num2str(gotoCount)+"/1", "Infos/"+gotoCount);
                        gotoCount = gotoCount +1;
                        disp("Infoblock erstellt für: "+ elemName);
                    end
                    add_line(subsystem.path+"/Infos", elemName+"/1", "BusCreator/"+i);
                end

                Simulink.BlockDiagram.arrangeSystem(subsystem.path+"/Infos");
                add_line(subsystem.path, "Infos/1", "Info/1");
           end
        end

        function calculateInertia(app, inertiaName, subsystem, currentNode)
%             disp("   ");
%             disp("----------> Suche J_red in "+subsystem.name+ " für: "+ inertiaName);

            [mechInPorts, mechOutPorts] = app.identifyMechInOutPorts(subsystem.path, currentNode);  % Raussuchen von mechanischen In- und Outports

            for i = 1:length(mechOutPorts)
                mechOutPort = mechOutPorts(i);
                if strcmp("J_red_"+ mechOutPort.name, inertiaName)
                    break;
                end
            end
            pathStruct = app.findEnergyPathForInertia(subsystem, mechOutPort.name, currentNode);

            % Addition aller reduzierten Massenträgheiten
            add_block("simulink/Commonly Used Blocks/Sum", subsystem.path+"/Infos/"+inertiaName, ...
                IconShape = "rectangular", ...
                Inputs = repmat('+', 1, length(pathStruct)));

            for j = 1:length(pathStruct)
                entry = pathStruct(j);
                entryInertiaName = entry.inertiaValue;
                blockName = entry.blockName;

                % jeder benötigte inertia Entry wird Ergänzt
                inertiaEntryBlockName = blockName+"_"+entryInertiaName;
%                 disp("- " + inertiaEntryBlockName);
                found = find_system(subsystem.path+"/Infos", "SearchDepth", 1, "Name", inertiaEntryBlockName);
                if isempty(found) % Ergänze BusSelector für gesuchtes Signal
                    add_block("simulink/Commonly Used Blocks/Bus Selector", subsystem.path+"/Infos/"+inertiaEntryBlockName, ...
                        OutputSignals=entryInertiaName );
                    add_line(subsystem.path+"/Infos", blockName+"/1", inertiaEntryBlockName +"/1");
                end

                % Reduzierung aller Trägheitsmomente
                reducedInertiasBlockName = blockName+"_"+entryInertiaName+"_reducedFor_"+inertiaName;
                inputs = repmat('*', 1, length(entry.factors)+1);
                add_block("simulink/Commonly Used Blocks/Product", subsystem.path+"/Infos/"+reducedInertiasBlockName, ...
                    Inputs = inputs);
                add_line(subsystem.path+"/Infos", inertiaEntryBlockName+"/1", reducedInertiasBlockName+"/1");
                add_line(subsystem.path+"/Infos", reducedInertiasBlockName+"/1", inertiaName+"/"+j);
                
                % Durchgehen durch alle Faktoren
                for k = 1:length(entry.factors)
                    factorBlockName = entry.factors(k).blockName;
                    factorName = entry.factors(k).factorName;
%                     disp("--- " +factorBlockName+"_"+factorName + "  -- "+entry.factors(k).extra);

                    found = find_system(subsystem.path+"/Infos", "SearchDepth", 1, "Name", factorBlockName+"_"+factorName);
                    if isempty(found) % Ergänze BusSelector für gesuchtes Signal
                        add_block("simulink/Commonly Used Blocks/Bus Selector", subsystem.path+"/Infos/"+factorBlockName+"_"+factorName, ...
                            OutputSignals=factorName);
                        add_line(subsystem.path+"/Infos", factorBlockName+"/1", factorBlockName+"_"+factorName+"/1");
                    end

                    found = find_system(subsystem.path+"/Infos", "SearchDepth", 1, "Name", factorBlockName+"_"+factorName+"_square");
                    if isempty(found) % Ergänze Square-Operator für gesuchtes Signal
                        add_block("simulink/Math Operations/Math Function", subsystem.path+"/Infos/"+factorBlockName+"_"+factorName+"_square", ...
                                Operator="square");
                        add_line(subsystem.path+"/Infos", factorBlockName+"_"+factorName+"/1", factorBlockName+"_"+factorName+"_square/1");
                    end

                    found = find_system(subsystem.path+"/Infos", "SearchDepth", 1, "Name", factorBlockName+"_"+factorName+"_extra");
                    if isempty(found) % Ergänze Square-Operator für gesuchtes Signal
                        add_block("simulink/Math Operations/Gain", subsystem.path+"/Infos/"+factorBlockName+"_"+factorName+"_extra", ...
                                Gain="1/"+entry.factors(k).extra);
                        add_line(subsystem.path+"/Infos", factorBlockName+"_"+factorName+"_square/1", factorBlockName+"_"+factorName+"_extra/1");
                    end

                    inputNum = k +1;
                    add_line(subsystem.path+"/Infos", factorBlockName+"_"+factorName+"_extra/1", reducedInertiasBlockName+"/"+inputNum);
                end
            end



        end

        function calculateGearRatio(app, ratioName, subsystem, currentNode)
            [mechInPorts, mechOutPorts] = app.identifyMechInOutPorts(subsystem.path, currentNode);  % Raussuchen von mechanischen In- und Outports

            % Bestimmen von inName und outName als Namen der verbundenen Ports
            if strcmp(ratioName, "i")
                inName = mechInPorts(1).name;
                outName = mechOutPorts(1).name;
            else
                found = false;
                for m = 1:length(mechInPorts)
                    for n = 1:length(mechOutPorts)
                        testName = "i_"+mechInPorts(m).name+"_"+mechOutPorts(n).name;
                        if strcmp(testName, ratioName)
                            inName = mechInPorts(m).name;
                            outName = mechOutPorts(n).name;
                            found = true;
                            break;
                        end
                    end
                    if found
                        break
                    end
                end
            end
            
            pathTable = app.findEnergyPathForGearRatio(subsystem, inName, outName, currentNode);

            subsystemPath = subsystem.path;
            add_block("simulink/Commonly Used Blocks/Product", subsystem.path+"/Infos/"+ratioName, ...
                Inputs = num2str(size(pathTable, 1)));

            for i = 1:size(pathTable, 1)
                pathSplit = split(pathTable(i, 1), "/");
                gearRatio = "i_"+pathTable(i, 2)+"_"+pathTable(i, 3);
                blockName = pathSplit(end);
%                 disp("-- "+blockName+" "+gearRatio)
                commaSeparatedList = "k";
                
                found = find_system(subsystem.path+"/Infos", "SearchDepth", 1, "Name", blockName+"_"+gearRatio);
                if isempty(found)
                    add_block("simulink/Commonly Used Blocks/Bus Selector", subsystem.path+"/Infos/"+blockName+"_"+gearRatio, ...
                        OutputSignals=gearRatio);
                    add_line(subsystem.path+"/Infos", blockName+"/1", blockName+"_"+gearRatio+"/1");
                end
                
                add_line(subsystem.path+"/Infos", blockName+"_"+gearRatio+"/1", ratioName+"/"+i);

            end
        end

        function pathTable = findEnergyPathForGearRatio(app, subsystem, inName, outName, currentNode)

            % Langlaufen der Kette
            energyConnections = subsystem.energyConnections;
            firstBlockPath = "";
            emptyPathTable = strings(0,3);
            for r = 1:length(energyConnections)
                if strcmp(energyConnections(r).srcPath, "/" + inName)
                    firstBlockPath = energyConnections(r).actualSystem + energyConnections(r).dstPath;
                    break;
                end
            end
            firstPathTable = [emptyPathTable; {firstBlockPath, energyConnections(r).dstPortName, ""}];

            if firstBlockPath == ""
                disp("Startverbindung nicht gefunden.");
                return;
            end
            
            [found, pathTable] = findInnerEnergyPathRorGearRatio(app, energyConnections, firstBlockPath, outName, currentNode, firstPathTable);
           
            if ~found
                disp("Kein Pfad gefunden.");
            end
        end

        function [found, pathTable] = findInnerEnergyPathRorGearRatio(app, energyConnections, currentBlockPath, destinationPortName, currentNode, oldPathTable)
            found = false;

            [mechInPorts, mechOutPorts] = app.identifyMechInOutPorts(currentBlockPath, currentNode);

            % Für jeden Outport prüfen, wohin er führt
            for z = 1:length(mechOutPorts)
                outPortName = mechOutPorts(z).name;
                for r = 1:length(energyConnections)
                    energyConnection = energyConnections(r);
                    if ~strcmp(energyConnection.actualSystem + energyConnection.srcPath, currentBlockPath) ...
                            || ~strcmp(energyConnection.srcPortName, outPortName)
                        continue;
                    end

                    dstPortName = extractAfter(energyConnection.dstPath, 1);

                    if strcmp(energyConnection.dstPortName, "-") ...
                            && ~strcmp(dstPortName, destinationPortName)
                        continue;
                    end

                    % CurrentBlock ist korrekt
                    oldPathTable(end, 1) = currentBlockPath;
                    oldPathTable(end, 3) = outPortName;
                    pathTable = oldPathTable;
                    
                    if strcmp(energyConnection.dstPortName, "-") ...
                            && strcmp(dstPortName, destinationPortName)  % Ziel erreicht
                        found = true;
                        return;
                    end

                    pathTable = [oldPathTable; {"?", energyConnection.dstPortName, "?"}];
                    nextBlockPath = energyConnection.actualSystem+energyConnection.dstPath;
                    [subFound, subPathTable]= findInnerEnergyPathRorGearRatio(app, energyConnections, nextBlockPath, destinationPortName, currentNode, pathTable);

                    if subFound
                        found= true;
                        pathTable = subPathTable;
                        return;
                    end
                end
            end
        end

        function pathStruct = findEnergyPathForInertia(app, subsystem, outPortName, currentNode)
            pathStruct = struct(...
                "inertiaValue", {}, ...
                "blockName", {}, ...
                "outPortName", {}, ...
                "factors", struct("blockName", {}, "factorName", {}, "power", {}, "extra", {}));

            energyConnections = subsystem.energyConnections;
            firstBlockPath = "";
            firstBlockName = "";
            firstOutPortName = "";
            for r = 1:length(energyConnections)
                if strcmp(energyConnections(r).dstPath, "/" + outPortName)
                    firstBlockPath = energyConnections(r).actualSystem + energyConnections(r).srcPath;
                    firstBlockName = extractAfter(energyConnections(r).srcPath, 1);
                    firstOutPortName = energyConnections(r).srcPortName;
                    break;
                end
            end
            newEntry = struct( ...
                "inertiaValue", "J_red_"+firstOutPortName, ...
                "blockName", firstBlockName, ...
                "outPortName", firstOutPortName, ...
                "factors", struct("blockName", {}, "factorName", {}, "power", {}, "extra", {}));
            pathStruct(end + 1) = newEntry;

            [found, pathStruct] = app.findInnerEnergyPathForInertia(energyConnections, firstBlockPath, currentNode, pathStruct);

        end

        function [found, pathStruct] = findInnerEnergyPathForInertia(app, energyConnections, currentBlockPath, currentNode, oldPathStruct)
            found = false;
            pathStruct = oldPathStruct;
            [mechInPorts, mechOutPorts] = app.identifyMechInOutPorts(currentBlockPath, currentNode);  % Ports analysieren

            if isempty(mechInPorts)   % Abbruch, wenn keine mechanischen Eingänge mehr vorhanden
                found = true;
                return;
            end

            baseStruct = oldPathStruct;

            for z = 1:length(mechInPorts)
                mechInPort = mechInPorts(z);

                for r = 1:length(energyConnections)
                    energyConnection = energyConnections(r);

                    if ~strcmp(energyConnection.actualSystem + energyConnection.dstPath, currentBlockPath) ...
                            || ~strcmp(energyConnection.dstPortName, mechInPort.name)  % Verbindung muss zu diesem Block und Port passen
                        continue;
                    end
                    
                    if strcmp(energyConnection.srcPortName, "-") % Angekommen an Port, Pfadende
                        found = true;
                        return;
                    end

                    % energyConnection führt zu sinnvollem nächsten Block
                    lastBlockName = oldPathStruct(end).blockName;
                    actualOutPortName = oldPathStruct(end).outPortName;
                    actualInPortName = mechInPort.name;
                    gearRatio = "i_"+actualInPortName+"_"+actualOutPortName;
                    power = num2str(length(oldPathStruct(end).factors)+1);
%                     num2str(length(mechOutPorts));
                    newFactor = struct("blockName", lastBlockName, "factorName", gearRatio, "power", power, "extra", num2str(length(mechOutPorts)));

                    lastFactors = oldPathStruct(end).factors;
                    newFactors = [lastFactors, newFactor];
                    
                    nextBlockPath = energyConnection.actualSystem + energyConnection.srcPath;
                    nextBlockName = extractAfter(energyConnections(r).srcPath, 1);
                    
                    newEntry = struct(...
                        "inertiaValue", "J_red_"+energyConnection.srcPortName, ...
                        "blockName", nextBlockName, ...
                        "outPortName", energyConnection.srcPortName, ...
                        "factors", newFactors);
                    pathStruct(end+1) = newEntry;
                    
                    [subFound, subPathStruct] = app.findInnerEnergyPathForInertia(energyConnections, nextBlockPath, currentNode, pathStruct);
                    
                    if subFound
                        found= true;
                        pathStruct = subPathStruct;
                    end
                end
            end
        end

        function [mechInPorts, mechOutPorts] = identifyMechInOutPorts(app, path, searchNode)
            mechInPorts = [];
            mechOutPorts = [];

            sysMLPath = app.SysmlPathFromSimPath(path);
            matchingNode = app.findNodeBySysMLPath(searchNode, sysMLPath);

            energyFlowPorts = matchingNode.NodeData.energyFlowPorts;
            for k = 1:length(energyFlowPorts)
                energyFlowPort = energyFlowPorts(k);
                if strcmp(energyFlowPort.type, "RotMechEnergyFlow") || strcmp(energyFlowPort.type, "TranslMechEnergyFlow")
                    if strcmp(energyFlowPort.direction, "in")
                        mechInPorts = [mechInPorts, energyFlowPort];
                    else
                        mechOutPorts = [mechOutPorts, energyFlowPort];
                    end
                end
            end
        end

        function simulinkModelGeneration(app)

            % Hauptmodell vorbereiten
            app.mainModelName = "MainModel";
            if bdIsLoaded(app.mainModelName)
                close_system(app.mainModelName, 0);                 % Schließe das Modell, falls es bereits offen ist
            end
            new_system(app.mainModelName);                          % Neues Simulink-Modell erstellen
%             open_system(app.mainModelName);
            disp("Erstelle Modell: " + app.mainModelName);
          
            addpath("EfficiencyModels\");
            addpath("JSON\");
            addpath("ContextModels\");
           
            % Einladen aller Parameter
            load("Basisparameter.mat", "parameter");
            assignin("base", "parameter", parameter);
            data = load('ModelParameters.mat');  % Lädt alles in eine Struktur
            fields = fieldnames(data);           % Alle Feldnamen (Variablennamen)
            for i = 1:numel(fields)
                assignin('base', fields{i}, data.(fields{i}));  % Jede Variable einzeln in den Base-Workspace
            end

            app.powertrainName = string(app.FidelityTree.Children(1).NodeData.name);
            app.powertrainType = string(app.FidelityTree.Children(1).NodeData.type);

            [subsystems, libraryBlocks, testSystems] = app.modelPreparation(app.FidelityTree.Children(1), app.dataStructCutted);
            
            app.createAllBusElements(subsystems, testSystems, app.dictionaryFileName);
            app.createEmptySubsystems(subsystems);
            app.createTestBlocks(testSystems);
            app.createLibraryBlocks(libraryBlocks);
            app.createEnergyFlowPorts(subsystems, testSystems);
            app.createSignalFlowPorts(subsystems, testSystems);
            app.createEnergyConnections(subsystems);
            app.createSignalConnections(subsystems);
            app.createTestBlockAppliances(testSystems);
            app.createInfoOutputs(subsystems);
            app.arrangeAllSubsystems(subsystems);   % Automatische Anordnung des Modells auf allen Ebenen

%             app.createOutsideHiLModel();

%             set_param("test01", 'MaxStep', '0.01');        % Maximale Schrittweite
%             set_param("test01", 'MinStep', '1e-3');        % Minimale Schrittweite
%             set_param("test01", 'SolverType', 'Variable-step');  % Variablen Schrittweite aktivieren
%             set_param("test01", 'StopTime', '500');

            % Zielpfad für Referenzdatei
            subsystemPath = app.mainModelName + "/" + app.powertrainName;
            referenceFile = fullfile(pwd, 'PowertrainSubsystem.slx');
            if isfile(referenceFile)
                delete(referenceFile);
            end
            Simulink.SubsystemReference.convertSubsystemToSubsystemReference(subsystemPath, referenceFile);

%             app.contextModelName = "LongitudinalVehicle";
            targetFolder = fullfile(pwd, "GeneratedModels");  % oder beliebiger Pfad
            copyName = app.contextModelName + "_"+ app.powertrainName;
            copyNameFull = fullfile(targetFolder, app.contextModelName + "_"+ app.powertrainName);
            
            if bdIsLoaded(copyName)
                close_system(copyName, 0);  % Schließe das Modell, falls es bereits offen ist
            end
            if isfile(copyNameFull)
                delete(copyNameFull);
            end

            % Kopie laden und öffnen
            sourcePath = fullfile("ContextModels", app.contextModelName + ".slx");
%             copyfile(app.contextModelName + ".slx", copyNameFull + ".slx", 'f');
            copyfile(sourcePath, copyNameFull + ".slx", 'f');
            load_system(copyNameFull);
            open_system(copyNameFull);
        end

        function createOutsideHiLModel(app)
            modelname = "test01";
            if bdIsLoaded(modelname)
                close_system(modelname, 0);                 % Schließe das Modell, falls es bereits offen ist
            end
            h = new_system(modelname);
            open_system(modelname);
            
            %Oberste Ebene
            add_block("HiL_Library/TestCycle_Environment","test01/Cycle_Env", "Position", [0 0 100 50]);
            add_block("HiL_Library/ControllLoop","test01/ControllLoop", "Position", [150 0 250 50]);
            add_block("simulink/Ports & Subsystems/Subsystem","test01/System", "Position", [300 0 400 50]);
            add_block("simulink/Commonly Used Blocks/Terminator", "test01/Info")
            delete_line("test01/System","In1/1","Out1/1");
            delete_block("test01/System/In1");
            delete_block("test01/System/Out1");
            
            %System
            add_block(app.mainModelName + "/" + app.powertrainName, "test01/System/Powertrain");
            add_block("HiL_Library/AuxiliaryConsumers","test01/System/AuxiliaryConsumers");
            add_block("HiL_Library/WheelsAndBrakes","test01/System/WheelsAndBrakes");
            add_block("HiL_Library/DrivingResistances","test01/System/DrivingResistances");
            add_block("HiL_Library/Vehicle","test01/System/Vehicle");
            add_block("HiL_Library/VehicleControlUnit","test01/System/VehicleControlUnit");
            add_block("built-in/Subsystem","test01/System/Infos");
            add_block("simulink/Ports & Subsystems/Out1","test01/System/Info");

            add_block("simulink/Ports & Subsystems/In Bus Element","test01/System/Cycle_AuxiliaryConsumers", ...
                PortName="Cycle", ...
                Element="");
            add_block("test01/System/Cycle_AuxiliaryConsumers","test01/System/Cycle_DrivingResistances", ...
                Element="");
            add_block("test01/System/Cycle_AuxiliaryConsumers","test01/System/Cycle_VehicleControlUnit", ...
                Element="");

            add_block("simulink/Ports & Subsystems/Out1","test01/System/s_act");
            add_block("simulink/Ports & Subsystems/Out1","test01/System/v_act");
            add_block("simulink/Ports & Subsystems/In1","test01/System/M_target_PID");

            % Infos
            add_block("simulink/Ports & Subsystems/In1","test01/System/Infos/Powertrain");
            add_block("simulink/Ports & Subsystems/In1","test01/System/Infos/WheelsAndBrakes");
            add_block("simulink/Ports & Subsystems/In1","test01/System/Infos/AuxiliaryConsumers");
            add_block("simulink/Ports & Subsystems/In1","test01/System/Infos/DrivingResistances");
            add_block("simulink/Ports & Subsystems/In1","test01/System/Infos/Vehicle");
            add_block("simulink/Ports & Subsystems/Out1", "test01/System/Infos/System");
            
            busElements(1) = Simulink.BusElement;
            busElements(1).Name = app.powertrainName;
            busElements(1).DataType = "Bus: Info_"+ app.powertrainType; % Namen der Busse müssen immer die der allgemeinen Klassen sein
            busElements(2) = Simulink.BusElement;
            busElements(2).Name = "WheelsAndBrakes";
            busElements(2).DataType = "Bus: Info_WheelsAndBrakes";
            busElements(3) = Simulink.BusElement;
            busElements(3).Name = "AuxiliaryConsumers";
            busElements(3).DataType = "Bus: Info_AuxiliaryConsumers";
            busElements(4) = Simulink.BusElement;
            busElements(4).Name = "DrivingResistances";
            busElements(4).DataType = "Bus: Info_DrivingResistances";
            busElements(5) = Simulink.BusElement;
            busElements(5).Name = "Vehicle";
            busElements(5).DataType = "Bus: Info_Vehicle";

            VehFdbkBus = Simulink.Bus;
            VehFdbkBus.Elements = busElements;
            assignin("base", "VehFdbk", VehFdbkBus);
          
            add_block("simulink/Signal Routing/Bus Creator", "test01/System/Infos/BusCreator", ...
                OutDataTypeStr="Bus: VehFdbk", ...
                InheritFromInputs="off", ...
                Inputs = num2str(length(busElements)));
            add_line("test01/System/Infos", "BusCreator/1", "System/1");
            
            add_line("test01/System/Infos", "Powertrain/1", "BusCreator/1");
            add_line("test01/System/Infos", "WheelsAndBrakes/1", "BusCreator/2");
            add_line("test01/System/Infos", "AuxiliaryConsumers/1", "BusCreator/3");
            add_line("test01/System/Infos", "DrivingResistances/1", "BusCreator/4");
            add_line("test01/System/Infos", "Vehicle/1", "BusCreator/5");

            add_block("simulink/Signal Routing/Bus Selector", "test01/System/Infos/Powertrain_Inertias", ...
                OutputSignals = "J_red_P_Drive_Out1,J_red_P_Drive_Out2");
            add_line("test01/System/Infos", "Powertrain/1", "Powertrain_Inertias/1");

            add_block("simulink/Signal Routing/Bus Selector", "test01/System/Infos/Wheels_Inertias", ...
                OutputSignals = "m_red,i");
            add_line("test01/System/Infos", "WheelsAndBrakes/1", "Wheels_Inertias/1");

            add_block("simulink/Commonly Used Blocks/Sum", "test01/System/Infos/Powertrain_Added", ...
                IconShape = "rectangular");
            add_line("test01/System/Infos", "Powertrain_Inertias/1", "Powertrain_Added/1");
            add_line("test01/System/Infos", "Powertrain_Inertias/2", "Powertrain_Added/2");

            add_block("simulink/Math Operations/Math Function", "test01/System/Infos/i_square", ...
                Operator="square");
            add_line("test01/System/Infos", "Wheels_Inertias/2", "i_square/1");

            add_block("simulink/Commonly Used Blocks/Product", "test01/System/Infos/Powertrain_red", ...
                	Inputs = "*/");
            add_line("test01/System/Infos", "Powertrain_Added/1", "Powertrain_red/1");
            add_line("test01/System/Infos", "i_square/1", "Powertrain_red/2");

            add_block("simulink/Commonly Used Blocks/Sum", "test01/System/Infos/m_red_sum", ...
                IconShape = "rectangular");
            add_line("test01/System/Infos", "Wheels_Inertias/1", "m_red_sum/1");
            add_line("test01/System/Infos", "Powertrain_red/1", "m_red_sum/2");

            add_block("simulink/Ports & Subsystems/Out1","test01/System/Infos/m_red");
            add_line("test01/System/Infos", "m_red_sum/1", "m_red/1", "autorouting", "on");

            Simulink.BlockDiagram.arrangeSystem("test01/System/Infos");

            % Goto-Verbindungen zu Infos
            add_block('simulink/Signal Routing/Goto', "test01/System/Goto1", 'GotoTag', "Goto1");
            add_line("test01/System", "Powertrain/1",  "Goto1/1");
            add_block('simulink/Signal Routing/From', "test01/System/From1", 'GotoTag', "Goto1");
            add_line("test01/System", "From1/1",  "Infos/1");

            add_block('simulink/Signal Routing/Goto', "test01/System/Goto2", 'GotoTag', "Goto2");
            add_line("test01/System", "WheelsAndBrakes/1",  "Goto2/1");
            add_block('simulink/Signal Routing/From', "test01/System/From2", 'GotoTag', "Goto2");
            add_line("test01/System", "From2/1",  "Infos/2");

            add_block('simulink/Signal Routing/Goto', "test01/System/Goto3", 'GotoTag', "Goto3");
            add_line("test01/System", "AuxiliaryConsumers/1",  "Goto3/1");
            add_block('simulink/Signal Routing/From', "test01/System/From3", 'GotoTag', "Goto3");
            add_line("test01/System", "From3/1",  "Infos/3");

            add_block('simulink/Signal Routing/Goto', "test01/System/Goto4", 'GotoTag', "Goto4");
            add_line("test01/System", "DrivingResistances/1",  "Goto4/1");
            add_block('simulink/Signal Routing/From', "test01/System/From4", 'GotoTag', "Goto4");
            add_line("test01/System", "From4/1",  "Infos/4");

            add_block('simulink/Signal Routing/Goto', "test01/System/Goto5", 'GotoTag', "Goto5");
            add_line("test01/System", "Vehicle/1",  "Goto5/1");
            add_block('simulink/Signal Routing/From', "test01/System/From5", 'GotoTag', "Goto5");
            add_line("test01/System", "From5/1",  "Infos/5");


              
            %Verbindungen in System
            add_line("test01/System", "Cycle_DrivingResistances/1", "DrivingResistances/1");
            add_line("test01/System", "Cycle_AuxiliaryConsumers/1", "AuxiliaryConsumers/2");
            add_line("test01/System", "Cycle_VehicleControlUnit/1", "VehicleControlUnit/1");

            add_line("test01/System", "Infos/1", "Info/1");
            add_line("test01/System", "Infos/2", "Vehicle/2");
            add_line("test01/System", "Vehicle/1", "DrivingResistances/2");
            add_line("test01/System", "Vehicle/2", "v_act/1");
            add_line("test01/System", "Vehicle/3", "s_act/1");
            add_line("test01/System", "Vehicle/2", "VehicleControlUnit/3");
            add_line("test01/System", "DrivingResistances/1", "WheelsAndBrakes/2");
            add_line("test01/System", "M_target_PID/1", "VehicleControlUnit/2");
            add_line("test01/System", "VehicleControlUnit/1", "WheelsAndBrakes/1");
            add_line("test01/System", "VehicleControlUnit/1", "AuxiliaryConsumers/1");
            add_line("test01/System", "VehicleControlUnit/1", "Vehicle/1");
            add_line("test01/System", "VehicleControlUnit/2", "Powertrain/1");
            add_line("test01/System", "Powertrain/2", "VehicleControlUnit/4");
            
            add_line("test01/System", ...
                get_param("test01/System/Powertrain","PortHandles").RConn(1), ...
                get_param("test01/System/WheelsAndBrakes","PortHandles").LConn(1));
            add_line("test01/System", ...
                get_param("test01/System/Powertrain","PortHandles").RConn(3), ...
                get_param("test01/System/WheelsAndBrakes","PortHandles").LConn(2));
            add_line("test01/System", ...
                get_param("test01/System/Powertrain","PortHandles").RConn(2), ...
                get_param("test01/System/AuxiliaryConsumers","PortHandles").LConn(1));
            add_line("test01/System", ...
                get_param("test01/System/WheelsAndBrakes","PortHandles").RConn(1), ...
                get_param("test01/System/Vehicle","PortHandles").LConn(1));
            add_line("test01/System", ...
                get_param("test01/System/DrivingResistances","PortHandles").RConn(1), ...
                get_param("test01/System/Vehicle","PortHandles").LConn(2));
            
            Simulink.BlockDiagram.arrangeSystem("test01/System");

            %Verbindungen oberster Ebene
            add_line("test01", "Cycle_Env/1", "ControllLoop/1", "autorouting", "on");
            add_line("test01", "Cycle_Env/1", "System/1", "autorouting", "on");
            add_line("test01", "ControllLoop/1", "System/2", "autorouting", "on");
            add_line("test01", "System/1", "Info/1", "autorouting", "on");
            add_line("test01", "System/2", "Cycle_Env/1", "autorouting", "on");
            add_line("test01", "System/3", "ControllLoop/2", "autorouting", "on");
        end

        function loadParameters(app)
            % Einladen der Paremeterdatei
            load("Basisparameter.mat", "parameter");
            assignin("base", "parameter", parameter);

            % Erstellung der benötigten LookupTables
            TorqueCurvePosAcc = Simulink.LookupTable;
            TorqueCurvePosAcc.Table.Value = parameter.Fahrzeug.Motor.Mahle.Drehmomentkennlinie.Drehmoment(1,:);
            TorqueCurvePosAcc.Breakpoints(1).Value = parameter.Fahrzeug.Motor.Mahle.Drehmomentkennlinie.Drehmoment(2,:);
            TorqueCurvePosAcc.StructTypeInfo.Name = "TorqueCurvePosAcc";
            assignin("base", "TorqueCurvePosAcc", TorqueCurvePosAcc);
            
            % TorqueCurveRecuLimit = Simulink.LookupTable;
            % TorqueCurveRecuLimit.Table.Value = parameter.Fahrzeug.Motor.Mahle.Drehmomentkennlinie.Drehmoment_reku_Grenz(1:11,:);
            % TorqueCurveRecuLimit.Breakpoints(1).Value = parameter.Fahrzeug.Getriebe.alpha_M_DMM;
            % TorqueCurveRecuLimit.Breakpoints(2).Value = parameter.Fahrzeug.Motor.Mahle.Drehmomentkennlinie.Drehmoment_reku_Grenz(12,:);
            % TorqueCurveRecuLimit.StructTypeInfo.Name = "TorqueCurveRecuLimit";
            % assignin("base", "TorqueCurveRecuLimit", TorqueCurveRecuLimit);
            
            HV_Heating = Simulink.LookupTable;
            HV_Heating.Table.Value = parameter.Fahrzeug.Nebenverbraucher.TMS.HV_Heizung_konv(1,:);
            HV_Heating.Breakpoints(1).Value = parameter.Fahrzeug.Nebenverbraucher.TMS.HV_Heizung_konv(2,:);
            HV_Heating.StructTypeInfo.Name = "HV_Heating";
            assignin("base", "HV_Heating", HV_Heating);
            
            AirConditioning = Simulink.LookupTable;
            AirConditioning.Table.Value = parameter.Fahrzeug.Nebenverbraucher.TMS.Klimaanlage_konv(1,:);
            AirConditioning.Breakpoints(1).Value = parameter.Fahrzeug.Nebenverbraucher.TMS.Klimaanlage_konv(2,:);
            AirConditioning.StructTypeInfo.Name = "AirConditioning";
            assignin("base", "AirConditioning", AirConditioning);
        end
    end
    


    
end