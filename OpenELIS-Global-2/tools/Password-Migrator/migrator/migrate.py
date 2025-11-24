import bcrypt
import binascii
import psycopg2 
import unicodedata

from getpass import getpass
from Crypto.Cipher import Blowfish

DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "clinlims"
DB_USERNAME = "clinlims"
DB_USER_PASSWORD = ""

def getDBConnectionInfo():
    global DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_USER_PASSWORD
    DB_HOST = raw_input("Enter the database server address (default " + DB_HOST + "): ") or DB_HOST
    DB_PORT = raw_input("Enter the database port number (default " + DB_PORT + "): ") or DB_PORT
    DB_NAME = raw_input("Enter the database name (default " + DB_NAME + "): ") or DB_NAME
    DB_USERNAME = raw_input("Enter the database user name (default " + DB_USERNAME + "): ") or DB_USERNAME
    DB_USER_PASSWORD = getpass("Enter the database user password: ")
    print

def getEncryptedPasswordRows(conn):
    cur = conn.cursor()
    sql = """
        SELECT password 
        FROM clinlims.login_user;
        """
    cur.execute(sql)
    rows = cur.fetchall()
    cur.close()
    return rows

def decryptPassword(ciphertextPassword):
    crypto = Blowfish.new(b"1a2b3c4d5e6f8g9h")
    plaintextPassword = crypto.decrypt(binascii.a2b_base64(ciphertextPassword)).decode("utf-8")
    plaintextPassword = removeControlCharacters(plaintextPassword)
    return plaintextPassword.encode("utf-8")

def removeControlCharacters(s):
    return "".join(ch for ch in s if unicodedata.category(ch)[0]!="C")

def hashPassword(plaintextPassword):
#    print("plaintext password is: " + plaintextPassword)
    hashedPassword = bcrypt.hashpw(plaintextPassword, bcrypt.gensalt(rounds=12, prefix=b"2a"))
    return hashedPassword 
    
def updatePassword(conn, ciphertextPassword, hashedPassword):
    print("updating " + ciphertextPassword + " to " + hashedPassword)
    cur = conn.cursor()
    sql = """
        UPDATE clinlims.login_user 
        SET password = %s 
        WHERE id = (
            SELECT id 
            FROM clinlims.login_user 
            WHERE password = %s
            ORDER BY id LIMIT 1
            )
        ;
        """
    cur.execute(sql, (hashedPassword, ciphertextPassword))
    conn.commit()
    cur.close()
    
def printResults(totalRows, migratedRows, numErrors, previouslyMigratedRows):
    print
    print("Total rows: " + str(totalRows))
    print("Number of rows migrated: " + str(migratedRows))
    print("Number of rows previously migrated: " + str(previouslyMigratedRows))
    print("Number of errors: " + str(numErrors))
    
    
def main():    
    getDBConnectionInfo()
    try:
        conn = psycopg2.connect(host=DB_HOST, port=DB_PORT, database=DB_NAME, user=DB_USERNAME, password=DB_USER_PASSWORD)
        
        rows = getEncryptedPasswordRows(conn)
        
        totalRows = len(rows)
        migratedRows = 0
        previouslyMigratedRows = 0;
        numErrors = 0;
        if (totalRows == 1):
            print("Migrating " + str(totalRows) +  " row")
        else:
            print("Migrating " + str(totalRows) +  " rows")
        print
        
        for row in rows:
            ciphertextPassword = row[0]
            if not ciphertextPassword.startswith("$2a$12$"):
                plaintextPassword = decryptPassword(ciphertextPassword)
                hashedPassword = hashPassword(plaintextPassword)
                if (bcrypt.checkpw(plaintextPassword, hashedPassword)):
                    try:
                        updatePassword(conn, ciphertextPassword, hashedPassword)
                        migratedRows += 1
                    except (Exception, psycopg2.DatabaseError) as error:
                        print(error)
                        numErrors += 1
                else:
                    print("Plaintext does not match hash. Error expected to have occurred.")
                    numErrors += 1
            else:
                print("Password already migrated, ignoring")
                previouslyMigratedRows += 1
        
        printResults(totalRows, migratedRows, numErrors, previouslyMigratedRows)
            
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()
    
main()
