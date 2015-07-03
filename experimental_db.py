'''
Interaction with Experimental DB
'''
import pymysql.cursors

class DB(object):
    def connect(self, db, user, passwd, host='localhost'):
        self.connection = pymysql.connect(
                db = db,
                user = user,
                passwd = passwd,
                host = host,
                cursorclass = pymysql.cursors.DictCursor     # returns searchs as key/value pairs
                )

    def stim_definition(self, stim_id):
        '''
        Grab all information for the requested stim_id
        '''

        with self.connection.cursor() as cursor:
            sql = 'SELECT * FROM stimuli WHERE id={0}'.format(stim_id)
            cursor.execute(sql)
            
            return cursor.fetchone()

    def get_experiments(self, stim_id):
        '''
        Grab all experiments from 'experiments' table in the DB that conform to this 'stim_id'
        '''

        with self.connection.cursor() as cursor:
            sql = 'SELECT * FROM experiments WHERE stimulus_id={0}'.format(stim_id)
            cursor.execute(sql)
            return cursor.fetchall()
        

