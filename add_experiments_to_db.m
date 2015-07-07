function add_experiments_to_db(start_time, parameters)
    % Add expeirmental information automatically to the DB
    %
    % This function can be called with 2 arguments or with none.
    % 1. When called with 2 arguments it allways adds the calling function
    % (whoever called add_expeirments_to_db) to global variable
    % expeirments_list. Depending on calling function, it might also
    % trigger sending info to the DB
    % 2. When called with no arguments it just triggers sending the
    % information in global variable 'experiments_list' to the db
    % 
    % How to use it:
    %   1. somewhere before your stimulus starts call something like this:
    %       start_t = datestr(now, 'HH:MM:SS');
    %       ...
    %       Your stimulus goes in here
    %       After your stimulus is done
    %       ...
    %       add_experiments_to_db(start_t, [parameters, varargin])
    %   
    %      where arguments = {req_arg_1, req_arg_2, ..., req_arg_n}
    %
    % Example
    %      function mystim(length, checker_size, varargin)
    %        ...
    %        start_t = datestr(now, 'HH:MM:SS');
    %        parameters = {length, checker_size}
    %        ...
    %        add_experiments_to_db(start_t, [parameters, varargin]);            
        
    % Sending information to the DB is achieved through 
    % add_experiment_to_db(stimulus, start_time,
    % end_time, parameters) (not "experiment" is singular) and is defined
    % below
    %
    % When calling add_experiment_to_db it will get parameter 'stimulus' from
    % the dbstack (function that called add_experiments_to_db) and 
    % 'end_time' from now().
    global experiments_list

    if ~(nargin==0 || nargin==2)
        error('add_experiments_to_db should be called with 0 or 2 parameters');
    end
    
    s = dbstack('-completenames');
    
    % although this function has 3 parameters, it might be called with no
    % parameters only to force sending experiments_list to the DB
    if (nargin)
        end_t = datestr(now, 'HH:MM:SS');
        stimulus = s(2).name;
%        stimulus = stimulus.name
 
        experiments_list{end+1} = {stimulus, start_time, end_t, parameters};
    end
    
    if size(s,1)==2
        % now it is the time to send everything to the DB 
        valid_species = ['M', 'S', 'R', 'K'];
        prompt = {'Your db name (do not use root)', ...
            'password', ...
            'species (M)ouse, (R)at, (S)alamander, mon(K)ey',...
            'Retina #'};
        default = {'', 'ganglion', 'S', '1'};
        user = '';
        while 1         % checks that connection to DB was stablished.
            while 1     %checks that parameters are correct
                input = inputdlg(prompt, 'DB info', 1, default);
                good_input = true;
                
                if isempty(input)
                    % user pressed cancel, probably doesn't want to send exp to DB
                    % database connection will fail bellow and will get
                    % prompted whether to quit for real
                    password = '-1';
                    break;
                end
                
                user = input{1};
                password = input{2};
                species = input{3};
                retina = str2double(input{4});

                if strcmp(user, 'root') || strcmp(user, '')
                    questdlg('user can''t be root nor empty', 'Wrong Input', 'OK','OK')
                    good_input = false;
                end
                
                if ~any(species==valid_species)
                    questdlg('species has to be ''M(ouse)'', ''S(alamander)'', ''R(at)'' or ''Monkey''', 'Wrong Input', 'OK','OK')
                    msgbox();
                    good_input = false;
                end
                
                if round(retina) ~= retina || retina==0
                    questdlg('reinta has to be an integer number', 'Wrong Input', 'OK','OK')
                    good_input = false;
                end
                
                if good_input
                    break
                end
            end
            
            % Try to connect to the db with the given name and password
            dbname = 'test';
            conn = database(dbname, user, password, 'Vendor', 'MySQL');
            
            % if connection failed, ask whether to try again
            if isconnection(conn)
                % get out of this forever loop and write data to DB
                break
            else
                answer = questdlg('Couldn''t connect to db. Do you want to try again?', ...
                    'Error connecting to DB', 'Yes', 'No', 'Yes');
            end
            
            if strcmp(answer, 'No')
                % clean experiments_list and return
                clear experiments_list
                return
            else
                user = '';
                password = '';
            end
        end
        
        % now we are connecting to the DB to add the experiment
        for i=1:length(experiments_list)
            add_experiment_to_db(conn, experiments_list{i}, species, retina)
        end
        
        clear experiments_list

        close(conn);
    end        
end

function add_experiment_to_db(conn, db_params, species, retina)
    % Add the given experiments with all associated parameters to the
    % database. 
    % 
    % Two different important cases should be handled
    % 1. When the user is running an experiment that is used frequently
    % for example RF that is already in the db.stimuli table) In that case
    % 'stim_id' is the 'stimuli' table id
    % 2. When the user is running an experiment that is not included in the
    % db, in that case stimulus_id is -1
    %
    % This function will get 'Resolution' from  screen and add the
    % corresponding index from 'screen' table. If the 'Resolution' is not
    % present in 'screen' table it will be added
    % parameters:
    %   conn = database('db_name','user','password','Vendor','MySQL');
    %
    %   db_params:  cell array with the following items
    %       db_params{1}:   stimulus = 'RF'
    %
    %       db_params{2}:   start_time = '15:59:30'
    %
    %       db_params{3}:   end_time = '17:03:04'
    %
    %       db_params{4}:   parameters:     a cell array
    %
    %   species/retina:     parameters to add to the DB but they don't come
    %                       from the stiulus but from the dialog box at the
    %                       end of the experiment
    
    stimulus = db_params{1};
    start_time = db_params{2};
    end_time = db_params{3};
    parameters = db_params{4};
    
    stimulus_id = get_stimulus_id(conn, stimulus);
    
    screen_id = get_screen_id(conn);
    
    user = get(conn, 'UserName');

    date = datestr(today, 'yyyy-mm-dd');
    start_time = datestr(start_time, 'HH:MM:SS');
    end_time = datestr(end_time, 'HH:MM:SS');
    params = parameters_to_text(parameters);
    
    % if 'stimulus' is not in the 'stimuli' table, the name of the
    % experiment will be lost. Instead I'm just adding it to the parameters
    % list at the beginning
    if stimulus_id==-1
        params = [stimulus, ', ', params];
    end
    

    columns = {'stimulus_id', 'user', 'date', 'start_time', 'end_time', ...
        'species', 'retina', 'params', 'screen_id'};
    values = {stimulus_id, user, date, start_time, end_time, ...
        species, retina, params, screen_id};

    insert(conn, 'experiments', columns, values)
end

function stimulus_id = get_stimulus_id(conn, stimulus)
    % Get the stimulus ID associated wtih stimulus (if more than one, use
    % the one with the largest version)
    sql = ['SELECT id FROM stimuli WHERE NAME=''', stimulus, ''' ORDER BY version DESC;'];
    cur = exec(conn, sql);
    cur = fetch(cur, 1);
    stimulus_id = cur.Data{1};
    
    if ischar(stimulus_id)
        stimulus_id = -1;
    end
end


function params = parameters_to_text(parameters)
    params = '';
    for i = 1:length(parameters)
        if ischar(parameters{i})
            params = [params, parameters{i}];
        elseif isnumeric(parameters{i})
            params = [params, mat2str(parameters{i})];
        else
            error('add_experiment_to_db can''t convert one parameter to text');
        end
        
        if i<length(parameters)
            params = [params, ', '];
        end
        
    end
end

function id = get_screen_id(conn)
    % Pull the screen_id corresponding to current monitor settings from the
    % 'screen' table. If this resolution is not present, add it.
    current = Screen('Resolution', max(Screen('Screens')));
    mysql = sprintf('SELECT id FROM screen WHERE width=%d and height=%d and pixel_size=%d and nominal_rate=%d', ...
        current(1).width, current(1).height, current(1).pixelSize, current(1).hz);
    cur = exec(conn, mysql);
    data = fetch(cur, 1);

    if strcmp('No Data', data.Data)
        % add this screen setup to DB
        columns = {'width', 'height', 'pixel_size', 'nominal_rate'};
        values = {current(1).width, current(1).height, current(1).pixelSize, current(1).hz};
        insert(conn, 'screen', columns, values);
        
        % grab the id just given to this setup
        cur = exec(conn, mysql);
        data = fetch(cur, 1);
        
    end
    
    % get nominal rate
    id = data.data{1};
end
