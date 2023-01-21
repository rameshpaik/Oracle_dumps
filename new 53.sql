---- this procedure willprepare the FBDI templates document header CSV records
    PROCEDURE INT_GET_AP_HEADERS_FBL_DETAILS(
        P_OFFSET   IN   NUMBER,
        P_LIMIT    IN   NUMBER,
        P_FILE_ID  IN   NUMBER,
        HASMORE    OUT  VARCHAR2,
        P_DATA     OUT  SYS_REFCURSOR
    )AS
        CNT NUMBER := 0;
    -- below statement will return the total number of invoices for specific file 
    BEGIN
        SELECT COUNT(*)
        INTO CNT
        FROM INT_AP_DOCUMENT_HEADER  DH,
             INT_AP_BATCH_HEADER     BH,
             INT_AP_FILE_HEADER      FH
        WHERE FH.FILE_HEADER_ID = P_FILE_ID
              AND BH.BATCH_HEADER_ID = DH.BATCH_HEADER_ID; 

    -- based on P_OFFSET and P_LIMIT value below condition will decide that this wheather the next iteration of this procedure is required or not based on hasmore value
        IF(P_OFFSET + P_LIMIT)>= CNT THEN
            HASMORE := 'false';
        ELSE
            HASMORE := 'true';
        END IF; 
    -- below statement will return document header CSV records based on offset and limit value
        OPEN P_DATA FOR SELECT *
                       FROM(
                           SELECT DH.INVOICE_HEADER_ID  AS STR
                           FROM INT_AP_FILE_HEADER      FH,
                                INT_AP_BATCH_HEADER     BH,
                                INT_AP_DOCUMENT_HEADER  DH
                           WHERE FH.FILE_HEADER_ID = BH.FILE_HEADER_ID
                                 AND BH.BATCH_HEADER_ID = DH.BATCH_HEADER_ID
                                 AND FH.FILE_HEADER_ID = P_FILE_ID
                       )
                       OFFSET P_OFFSET ROWS FETCH NEXT P_LIMIT ROWS ONLY;

    END;
	
CNT=10000	
P_OFFSET=0
P_LIMIT=1000


end of iteration 
P_OFFSET=P_OFFSET+P_LIMIT==0+1000=1000
1000+1000=2000

OIC
while (HASMORE)
loop wil work

INT_GET_AP_HEADERS_FBL_DETAILS will be called in loop





