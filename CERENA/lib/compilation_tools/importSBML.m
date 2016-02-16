function System = importSBML(modelname)
    try
        model = TranslateSBML([modelname '.sbml']);
    catch
        model = TranslateSBML([modelname '.xml']);
    end
    
    %% model file
    stochStates = {};
    if isfield(model,'time_symbol')
        if ~isempty(model.time_symbol)
            System.time = model.time_symbol;
        else
            syms time;
            System.time = time;
        end
    else
        syms time;
        System.time = time;
    end
    
    str_comp = '{''';
    for i = 1:length(model.compartment)
        System.compartments{i} =  model.compartment(i).id;
        str_comp = [str_comp, model.compartment(i).id,''', '''];
        if model.compartment(i).isSetSize
            System.volumes(i) = model.compartment(i).size;
        else
            System.volumes(i) = 1;
        end
    end
    str_comp = [str_comp(1:end-3),'};'];
    
    n_s = length(model.species);
    System.state.variable = sym(zeros(n_s,1));
    System.state.number = n_s;
    str_sp_comp = '{''';
    str_sp_type= '{';
    str_sp_name = '{''';
    System.state.variable = sym({model.species.id});
    for i = 1:n_s
        if isempty(model.species(i).name)
            System.state.name{i} = model.species(i).id;
        else
            System.state.name{i} = model.species(i).name;
        end
        str_sp_name = [str_sp_name,System.state.name{i},'''; '''];
        System.state.compartment{i} = model.species(i).compartment;
        str_sp_comp = [str_sp_comp, model.species(i).compartment,'''; '''];
        if(~isempty(stochStates))
            if ismember(System.state.variable(i),stochStates)
                System.state.type{i} = 'stochastic';
                str_sp_type = [str_sp_type, '''stochastic''; '];
            else
                System.state.type{i} = 'moment';
                str_sp_type = [str_sp_type, '''moment''; '];
            end
        end
        % Initial conditions assuming no assignment rules
        if model.species(i).isSetInitialAmount
            System.state.mu0(i) = model.species(i).initialAmount;
        elseif model.species(i).isSetInitialConcentration
            volume_tmp = System.volumes(strcmp(model.species(i).compartment,System.compartments));
            System.state.mu0(i) = model.species(i).initialConcentration * volume_tmp;
        else
            System.state.mu0(i) = 0;
        end
    end
    str_sp_comp = [str_sp_comp(1:end-3),'};'];
    str_sp_type = [str_sp_type,'};'];
    str_sp_name = [str_sp_name(1:end-3),'};'];
    lb = zeros(n_s,1);
    ub = 10*transpose(System.state.mu0);
    System.state.xmin = lb;
    System.state.xmax = ub;
    System.state.C0 = zeros(System.state.number*(System.state.number+1)/2,1);
    
    % Define parameter vector:
    n_p = length(model.parameter);
    str_par_name = '{''';
    System.parameter.name = cell(n_p,1);
    System.parameter.variable = sym('p',[n_p,1]);
    for i = 1:n_p
        isRule = false;
        for ii=1:length(model.rule)
            if(strcmp(model.rule(ii).variable, model.parameter(i).id))
                isRule = true;
            end
            if(strcmp(model.rule(ii).variable, model.parameter(i).name))
                isRule = true;
            end
        end
        if ~isRule
            System.parameter.variable(i) = sym(model.parameter(i).id);
            if isempty(model.parameter(i).name)
                System.parameter.name{i} = model.parameter(i).id;
            else
                System.parameter.name{i} = model.parameter(i).name;
            end
            str_par_name = [str_par_name,System.parameter.name{i},'''; '''];
        end
    end
    str_par_name = [str_par_name(1:end-3),'};'];
    
    n_r = length(model.reaction);
    rulevars = sym({model.rule.variable});
    for i = 1:n_r
        n_s_i = length(model.reaction(i).reactant);
        System.reaction(i).educt = sym({model.reaction(i).reactant.species});
        n_s_i = length(model.reaction(i).product);
        System.reaction(i).product = sym({model.reaction(i).product.species});
        tmpProp = sym(model.reaction(i).kineticLaw.math);
        if isfield(model.reaction(i).kineticLaw,'parameter')
            if ~isempty(model.reaction(i).kineticLaw.parameter)
                tmpProp = subs(tmpProp,{model.reaction(i).kineticLaw.parameter.id},...
                    cellfun(@(x) strcat([model.reaction(i).id,'_'],x),{model.reaction(i).kineticLaw.parameter.id},'UniformOutput',false));
            end
        end
        tmpProp = char(tmpProp);
        for jj=1:length(model.functionDefinition)
            tmpfun = model.functionDefinition(jj).math;
            tmpfun = strrep(tmpfun, 'lambda(', '');
            tmpfun = tmpfun(1:end-1);
            
            C = textscan(tmpfun, '%s', 'Whitespace', ',');
            C = C{1};
            
            tmpProp = replaceFunction(tmpProp, model.functionDefinition(jj).id, C(1:end-1), C(end));
        end
        
        % replace rules
        tmpProp = sym(tmpProp);
        vars = symvar(tmpProp);

        ruleidx = ismember(rulevars,vars);
        if(any(ruleidx))
            findrule = true;
        end
        while(findrule)
            for jj=find(ruleidx)
                tmpProp = subs(tmpProp, model.rule(jj).variable, ['(' model.rule(jj).formula ')']);
            end
            findrule = false;
            vars = symvar(tmpProp);
            ruleidx = ismember(rulevars,vars);
            if(any(ruleidx))
                findrule = true;
            end
        end
        tmpProp = char(tmpProp);
        
        % replace power function
        tmpProp = replacePowerFunction(tmpProp);
        tmpProp = replacePowerFunction(tmpProp, 'pow');
        for j = 1:length(model.compartment)
            if isnumeric(model.compartment(j).size)
                tmpProp = strrep(tmpProp,model.compartment(j).id,num2str(model.compartment(j).size));
            else
                tmpProp = strrep(tmpProp,model.compartment(j).id,model.compartment(j).size);
            end
        end
        System.reaction(i).propensity = sym(tmpProp);
    end
    
    System.output.variable = transpose(System.state.variable);
    System.output.function = transpose(System.state.variable);
    System.output.number   = length(System.output.variable);
    System.output.name = System.state.name;
    
    System.input.function = [];
    System.input.variable = [];
    System.input.number = 0;
    System.input.type     = {};
    System.input.name     = {};
    
    % fill parameters
    svar = symvar([System.reaction.propensity]);
    isState = ismember(symvar([System.reaction.propensity]),System.state.variable);
    isParam = ismember(symvar([System.reaction.propensity]),System.parameter.variable);
    isInput = ismember(symvar([System.reaction.propensity]),System.input.variable);
    parsed_parameters = svar(not(isState) & not(isInput) & not(isParam));
    System.parameter.variable = [System.parameter.variable, parsed_parameters];
    System.parameter.name = {System.parameter.name, arrayfun(@char,parsed_parameters,'UniformOutput',false)};
    
    
    %% Writing the model definition file
    clear([modelname '.m']);
    fid = fopen(['modelDef_',modelname '.m'], 'w');
    fprintf(fid, '%% Definition of symbolic variables\n');
    str_sp_sym = char(transpose(System.state.variable));
    fprintf(fid,['syms   ',strrep(str_sp_sym(10:end-3),',',''),'\n']);
    str_par_sym = char(System.parameter.variable);
    fprintf(fid,['syms   ',strrep(str_par_sym(10:end-3),',',''),'\n']);
    fprintf(fid,['syms   ',char(System.time),'\n']);
    fprintf(fid, '%% Define state vector\n');
    fprintf(fid, ['System.time = ',char(System.time),';\n']);
    fprintf(fid, ['System.compartments = ',str_comp,'\n']);
    fprintf(fid, ['System.volumes      = [',num2str(System.volumes),'];\n']);
    fprintf(fid, ['System.state.variable    = ',strrep(str_sp_sym(9:end-2),',',';'),';\n']);
    fprintf(fid, ['System.state.compartment = ', str_sp_comp, '\n']);
    fprintf(fid,  'System.state.number      = length(System.state.variable);\n');
    fprintf(fid, ['System.state.type        = ',str_sp_type,'\n']);
    fprintf(fid, ['System.state.name        = ',str_sp_name,'\n']);
    fprintf(fid, ['System.state.xmin        = transpose([', num2str(System.state.xmin'),']);\n']);
    fprintf(fid, ['System.state.xmax        = transpose([', num2str(System.state.xmax'),']);\n']);
    fprintf(fid, ['System.state.mu0         = transpose([', num2str(System.state.mu0),']);\n']);
    fprintf(fid,  'System.state.C0          = zeros(System.state.number*(System.state.number+1)/2,1);\n');
    fprintf(fid, ['System.parameter.variable = [',strrep(str_par_sym(10:end-3),',',';'),'];\n']);
    fprintf(fid, ['System.parameter.name     = ',str_par_name,'\n\n']);
    fprintf(fid, '%% Define reactions\n');
    fprintf(fid, ['System.scaleIndicator = ''macroscopic'';\n']);
    for ir = 1:n_r
        fprintf(fid, ['%% (R',num2str(ir),')\n']);
        str_educt = char(System.reaction(ir).educt);
        str_product = char(System.reaction(ir).product);
        if length(System.reaction(ir).educt)>1
            fprintf(fid, ['System.reaction(',num2str(ir),').educt      = ', str_educt(9:end-2),';\n']);
        else
            fprintf(fid, ['System.reaction(',num2str(ir),').educt      = [', str_educt,'];\n']);
        end
        if length(System.reaction(ir).product)>1
            fprintf(fid, ['System.reaction(',num2str(ir),').product      = ', str_product(9:end-2),';\n']);
        else
            fprintf(fid, ['System.reaction(',num2str(ir),').product      = [', str_product,'];\n']);
        end
        fprintf(fid, ['System.reaction(',num2str(ir),').propensity      = ', char(System.reaction(ir).propensity),';\n\n']);
    end
    str_output_var = char(System.output.variable);
    if length(str_output_var)>1
        fprintf(fid,['System.output.variable = ', str_output_var(9:end-2),';\n']);
    else
        fprintf(fid,['System.output.variable = [', str_output_var,'];\n']);
    end
    str_output_fun = char(System.output.function);
    if length(str_output_fun)>1
        fprintf(fid,['System.output.function = ', str_output_fun(9:end-2),';\n']);
    else
        fprintf(fid,['System.output.function = [', str_output_fun,'];\n']);
    end
    fprintf(fid ,'System.output.number   = length(System.output.variable);\n');
    % fprintf(fid ,['System.output.type     = ',str_sp_type,'\n']);
    fprintf(fid ,['System.output.name     = ',str_sp_name,'\n\n']);
    fprintf(fid, 'System.input.function = [];\n');
    fprintf(fid, 'System.input.variable = [];\n');
    fprintf(fid, 'System.input.number = 0;\n');
    fprintf(fid, 'System.input.name     = {};\n\n');
    fclose(fid);
    
function str = replaceFunction(str, funstr, C, funmat)
    
    funindex = strfind(str, [funstr '(']);
    while(~isempty(funindex))
        
        substr = str(funindex(1):end);
        
        openindex = strfind(substr, '(');
        closeindex = strfind(substr, ')');
        
        mergedindex = [openindex closeindex];
        rankingindex = [ones(size(openindex)) -ones(size(closeindex))];
        
        [sortedmergedindex, isortedindex] = sort(mergedindex);
        sortedrankingindex = rankingindex(isortedindex);
        
        endfunindex = find(cumsum(sortedrankingindex)==0);
        if(isempty(endfunindex))
            error('bracketing error close to function %s', funstr);
        end
        endfunindex = sortedmergedindex(endfunindex(1));
        
        substr = substr(openindex+1:endfunindex-1);
        
        D = textscan(substr, '%s', 'Whitespace', ',');
        D = D{1};
        if(length(C)~=length(D))
            error('input output parameter mismatch');
        end
        
        funtmplate = funmat;
        for j=1:length(D)
            funtmplate = strrep(funtmplate, C{j}, ['(' D{j} ')']);
        end
        funtmplate = ['(' funtmplate ')']; %#ok<AGROW>
        % disp(funtmplate)
        
        if(funindex(1)-1>1 && funindex(1)+endfunindex<length(str))
            str = [str(1:funindex(1)-1) funtmplate str(funindex(1)+endfunindex:end)];
        elseif(funindex(1)-1>1)
            str = [str(1:funindex(1)-1) funtmplate];
        elseif(funindex(1)+endfunindex<length(str))
            str = [funtmplate str(funindex(1)+endfunindex:end)];
        else
            str = funtmplate;
        end
        str = cell2mat(str);
        % disp(str)
        
        funindex = strfind(str, funstr);
    end
    % disp(str)
    
    str = char(sym(str));
    
    
function str = replacePowerFunction(str, funstr)
    
    if(nargin<2)
        funstr = 'power';
    end
    % disp(str);
    funindex = strfind(str, [funstr '(']);
    while(~isempty(funindex))
        
        brl = computeBracketLevel(str);
        
        
        argstart = funindex(1)+length(funstr)+1;
        argend = find(brl(argstart:end)<brl(funindex(1)),1,'first')-3+argstart;
        
        args = strsplit(str(argstart:argend),',');
        str = [str(1:(funindex-1)) '(' args{1} ')^(' args{2} ')' str((argend+2):end)];
        
        funindex = strfind(str, [funstr '(']);
    end
    % disp(str)
    
    str = char(sym(str));
    
    
    
