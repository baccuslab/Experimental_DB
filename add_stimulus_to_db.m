function add_stimulus_to_db(conn, stimulus, version, explanation , repeated_seq, non_repeated_seq, ...
        uniform_field, natural_scene, gaussian_white_noise, pink_noise, ...
        binary_noise)
    % Will insert the given stimulus into the given database connection
    % 'conn'
    %
    % Parameters:
    %   conn = database('db_name','user','password','Vendor','MySQL');
    %   stimulus = 'RF'
    %   
    file = which(stimulus);
    
    columns = {'name', 'version', 'Explanation', 'repeated_seq', 'non_repeated_seq', ...
        'uniform_field', 'natural_scene', 'gaussian_white_noise', 'pink_noise', ...
        'binary_noise', 'file'};
    
    values = {stimulus, version, explanation , repeated_seq, non_repeated_seq, ...
        uniform_field, natural_scene, gaussian_white_noise, pink_noise, ...
        binary_noise, file};
    
    % next 'stimuli' is the name of the table we are inserting data into
    insert(conn, 'stimuli', columns, values)
end