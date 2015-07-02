# Experimental_DB
These are a series of scripts that work with a mysql data base (in your laptop, stimulating computer and server) to automatically keep track of every experiment we perform. DB Schema will surely have to be revisited once we start using for real.
Adding Stimuli, Sequences and Images to the DB
To add stimuli/sequences to the db you can either do it straight from the DB or from matlab. The idea is very simple. I created a very simple wrapper   add_stimulus_to_db that helps a little bit with stimulus, grabbing the path to the file for you. Adding to stimuli/sequences should be done only once per stimulus/sequence and will raise an error if the combination of ‘Name' and 'version’ are not unique for the stimuli table.
The idea is that only when new stimuli are generated we have to update Stimuli/Sequences/Images tables but the Experiments table gets updated with every experiment.

# Adding experiments to the DB:
1. In your experimental code, somewhere before your stimulus starts call something like this:

     start_t = datestr(now, 'HH:MM:SS');
     
2. Then after your stimulus:

    add_experiments_to_db(start_t, [parameters, varargin])
    
      
    where arguments = {req_arg_1, req_arg_2, ..., req_arg_n}
    
# Example
    
    Function mystim(length, checker_size, varargin)
    
            ...
    
            start_t = datestr(now, 'HH:MM:SS');
    
            parameters = {length, checker_size}
    
            ...
    
            add_experiments_to_db(start_t, [parameters, varargin]);  

The idea behind this design is that in the stimulating computer will have a "stimulus", "sequences" and "Natural Scenes" folders
that will be backed up in github and therefore knowing the id and the insertion date is all we need to know what 
stimulus/sequence/image we are talking about.

To add a sequence or natural scene from matlab you can run:
insert(conn, ‘table_name’, columns, values)
where:

     conn = database(‘db_name’, ‘user_name’, ‘password’, ‘Vendor’, ‘MySQL’)

     columns = {‘col1’, ‘col2’, …, ‘coln’}           see bellow depending on which table you are inserting into

     values = {val_1, val_2, …, val_n}   numeric values don’t use “ ‘ “ but strings do need it

You don’t need to pass all the columns, only the ones you are supplying values for.
Example:

     insert(conn, ’sequenes’, {’type’, ‘file’}, {‘pink_noise’, ’some path to a file’}) 
