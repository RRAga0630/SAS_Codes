option compress = yes;

libname SFDC 'E:\SASDATA\COrtiz\EC Data';

/* 1. Pull revenue data */
PROC SQL;
CONNECT TO ODBC AS myODBC(datasrc=ICDW_PROD user=DM_GCH password=intercall);
CREATE TABLE SFDC.FINAL_REV_DATA AS
SELECT * FROM CONNECTION TO myODBC
	(SELECT   
	MONTH_A.MONTH_START,    	
	CASE   
		WHEN COMPANY_A.ENTITY_CODE IN ('V18','V19') AND COMPANY_A.CUSTOM_SUB_ENTITY_ID IS NOT NULL THEN COMPANY_A.CUSTOM_SUB_ENTITY_ID   
		WHEN COMPANY_A.ENTITY_CODE IN('NAVL','-1','K7Z','999','902','907','905','901','909','903','910','908','904','906','900','DRT') THEN TO_CHAR(COMPANY_A.COMPANY_ID)   
		ELSE COMPANY_A.ENTITY_CODE   
		END AS ENTITY_CODE,   
	CASE   
		WHEN COMPANY_A.ENTITY_CODE IN ('V18','V19') AND COMPANY_A.CUSTOM_SUB_ENTITY_ID IS NOT NULL THEN COMPANY_A.CUSTOM_SUB_ENTITY_NAME   
		WHEN COMPANY_A.ENTITY_CODE IN ('NAVL','-1','K7Z','999','902','907','905','901','909','903','910','908','904','906','900','DRT') THEN COMPANY_A.COMPANY_NAME   
		ELSE ENTITY_A.ENTITY_NAME   
		END AS ENTITY_NAME,   
	TO_CHAR(COMPANY_A.COMPANY_ID) AS COMPANY_ID, 
	CCA_CO_LIST.COMPANY_NUMBER as COMPANY_NUMBER_CCA,
	COMPANY_A.COMPANY_NAME, 
        	(CASE WHEN PRODUCT_A.CHARGE_CODE like 'TNU%' THEN 'TNU' ELSE
	NVL(FIN_PROD_OVERRIDE_A.FINANCE_PRODUCT,NVL(FIN_PROD_A.FINANCE_PRODUCT,'Other')) END) AS FINANCE_PRODUCT,  
	CASE WHEN GL_MAP_A.NATURAL_ACCOUNT IN ('5751','5386','5153') THEN 'Y' ELSE 'N' END AS FLEX_REVENUE_FLAG,   
	decode(COMPANY_A.BU_ID,2,'EMEA',3,'APAC',4,'CANADA',1,'USA','Other') AS BU,   
	'Metranet' as SourceData, 
	SUM(INVOICE_A.INV_QUANTITY) AS QTY,    
	SUM(INVOICE_A.INV_MINUTES) AS MINS,    
	SUM(INVOICE_A.USD_CHARGE) AS USD_REV,    
	Sum(INVOICE_A.INV_CHARGE) AS INV_REV    
FROM    
	DM_GCH.GCH_FCT_INVOICE INVOICE_A    
		JOIN DM_GCH.GCH_DIM_PRODUCT PRODUCT_A ON    
	PRODUCT_A.GCH_CHARGE_CODE_KEY = INVOICE_A.GCH_CHARGE_CODE_KEY    
		JOIN DM_GCH.GCH_DIM_SERVICE SERVICE_A ON    
	SERVICE_A.GCH_SERVICE_KEY = PRODUCT_A.GCH_SERVICE_KEY      
		JOIN GBL_DIMS.GBL_CHARGE_CODE_DIM GBL_CHARGE_CODE_DIM_A ON    
	GBL_CHARGE_CODE_DIM_A.GBL_CHARGE_CODE_KEY = PRODUCT_A.GBL_DIMS_GBL_CHARGE_CODE_KEY    
		JOIN DM_GCH.GCH_DIM_service SERVICE_B ON    
	SERVICE_B.GCH_SERVICE_KEY = INVOICE_A.GCH_SERVICE_KEY     
		JOIN DM_GCH.GCH_DIM_MONTH MONTH_A ON    
	MONTH_A.MONTH_ID = INVOICE_A.MONTH_ID    
		JOIN DM_GCH.GCH_DIM_SOURCE SOURCE_A ON    
	SOURCE_A.SOURCE_ID = INVOICE_A.SOURCE_ID    
		JOIN DM_GCH.GCH_DIM_ACCOUNT ACCOUNT_A ON    
	ACCOUNT_A.GCH_ACCOUNT_KEY = INVOICE_A.GCH_ACCOUNT_KEY    
		JOIN DM_GCH.GCH_DIM_COMPANY COMPANY_A ON    
	COMPANY_A.GCH_COMPANY_KEY = ACCOUNT_A.GCH_COMPANY_KEY    
		JOIN DM_GCH.GCH_DIM_SALES SALES_A ON    
	SALES_A.GCH_SALES_REP_KEY = COMPANY_A.GCH_SALES_REP_KEY    
		LEFT OUTER JOIN DM_GCH.GCH_DIM_ENTITY ENTITY_A ON    
	ENTITY_A.ENTITY_CODE = COMPANY_A.ENTITY_CODE    
		JOIN GBL_DIMS.COMPANY_DIM COMPANY_DIM_A ON    
	COMPANY_DIM_A.COMPANY_KEY = COMPANY_A.GBL_DIMS_COMPANY_KEY    
		LEFT OUTER JOIN GBL_DIMS.FIN_GBL_GL_MAPPING_DIM GL_MAP_A ON   
	GL_MAP_A.CHARGE_CODE = GBL_CHARGE_CODE_DIM_A.CHARGE_CODE   
	AND GL_MAP_A.CHARGE_TYPE = GBL_CHARGE_CODE_DIM_A.CHARGE_TYPE   
		LEFT OUTER JOIN GBL_DIMS.FIN_PROD_MAPPING_DIM FIN_PROD_A ON   
	FIN_PROD_A.NATURAL_ACCOUNT = GL_MAP_A.NATURAL_ACCOUNT   
	AND FIN_PROD_A.PRODUCT = GL_MAP_A.PRODUCT   
	AND FIN_PROD_A.GBL_SERVICE_KEY = GBL_CHARGE_CODE_DIM_A.SERVICE_KEY   
		LEFT OUTER JOIN GBL_DIMS.FIN_PROD_OVERRIDE_DIM FIN_PROD_OVERRIDE_A ON   
	FIN_PROD_OVERRIDE_A.CHARGE_CODE = GBL_CHARGE_CODE_DIM_A.CHARGE_CODE   
	AND FIN_PROD_OVERRIDE_A.CHARGE_TYPE = GBL_CHARGE_CODE_DIM_A.CHARGE_TYPE  
		LEFT OUTER JOIN DWREP_USER.MONTH_CCA_COMPANY CCA_CO_LIST ON
	CCA_CO_LIST.COMPANY_NUMBER = COMPANY_DIM_A.COMPANY_NUMBER
	AND CCA_CO_LIST.MONTH_START = MONTH_A.MONTH_START
WHERE MONTH_A.MONTH_START >= TO_DATE('2017-01-01','YYYY-MM-DD')  
	AND 
	GL_MAP_A.PRODUCT IN ('01','02','03','04','06') 
GROUP BY    
	MONTH_A.MONTH_START,    
	CASE   
		WHEN COMPANY_A.ENTITY_CODE IN ('V18','V19') AND COMPANY_A.CUSTOM_SUB_ENTITY_ID IS NOT NULL THEN COMPANY_A.CUSTOM_SUB_ENTITY_ID   
		WHEN COMPANY_A.ENTITY_CODE IN('NAVL','-1','K7Z','999','902','907','905','901','909','903','910','908','904','906','900','DRT') THEN TO_CHAR(COMPANY_A.COMPANY_ID)   
		ELSE COMPANY_A.ENTITY_CODE   
		END,   
	CASE   
		WHEN COMPANY_A.ENTITY_CODE IN ('V18','V19') AND COMPANY_A.CUSTOM_SUB_ENTITY_ID IS NOT NULL THEN COMPANY_A.CUSTOM_SUB_ENTITY_NAME   
		WHEN COMPANY_A.ENTITY_CODE IN ('NAVL','-1','K7Z','999','902','907','905','901','909','903','910','908','904','906','900','DRT') THEN COMPANY_A.COMPANY_NAME   
		ELSE ENTITY_A.ENTITY_NAME   
		END,   
	COMPANY_A.COMPANY_ID,  
	CCA_CO_LIST.COMPANY_NUMBER,
	COMPANY_A.COMPANY_NAME,
        CASE WHEN PRODUCT_A.CHARGE_CODE like 'TNU%' THEN 'TNU' ELSE
	NVL(FIN_PROD_OVERRIDE_A.FINANCE_PRODUCT,NVL(FIN_PROD_A.FINANCE_PRODUCT,'Other')) END,  
	CASE WHEN GL_MAP_A.NATURAL_ACCOUNT IN ('5751','5386','5153') THEN 'Y' ELSE 'N' END, 
	decode(COMPANY_A.BU_ID,2,'EMEA',3,'APAC',4,'CANADA',1,'USA','Other')

UNION ALL
SELECT MONTH_START,
       CASE 
			WHEN TO_CHAR(ENTITY_CODE) IS NULL then TO_CHAR(COMPANY_ID) 
			ELSE TO_CHAR(ENTITY_CODE) 
			END AS ENTITY_CODE,
       CASE 
       		WHEN TO_CHAR(ENTITY_NAME) IS NULL then TO_CHAR(COMPANY_NAME) 
			ELSE TO_CHAR(ENTITY_NAME) 
			END AS ENTITY_NAME,
       COMPANY_ID,
       null AS COMPANY_NUMBER_CCA,
       COMPANY_NAME,
       to_char(FINANCE_PRODUCT),
       null AS FLEX_REVENUE_FLAG,
       'USA' as BU,
       'ITC' as SourceData,
       SUM(QTY) AS QTY,
       SUM(MINS) AS MINS,
       SUM(USD_REV) AS USD_REV,
       SUM(INV_REV) AS INV_REV
FROM DM_GCH.STG_REV_REAL_SOURCE_COMPANY
WHERE MONTH_START >= TO_DATE('2017-01-01','YYYY-MM-DD') AND WEST_BUSINESS_UNIT = 'IP'
GROUP BY MONTH_START, ENTITY_CODE, ENTITY_NAME, COMPANY_ID, COMPANY_NAME, FINANCE_PRODUCT
ORDER BY MONTH_START, ENTITY_CODE, ENTITY_NAME, COMPANY_ID, COMPANY_NAME, FINANCE_PRODUCT);
QUIT;


/*2. Pull 3 firmo data from sf_entity__c table */
PROC SQL;
CONNECT TO ODBC AS myODBC(datasrc=ICDW_PROD user=DM_GCH password=intercall);
CREATE TABLE SFDC.FIRMODATA_ENTITY AS
SELECT * FROM CONNECTION TO myODBC
	(SELECT DISTINCT ENTITY_CODE__C,
	NAME,
	NO_EMPLOYEES__C,
	NAICS__C,
	HQ_COUNTRY__C,
	HQ_REGION__C
FROM SFDC.SF_ENTITY__C);
QUIT;

/* Pull 3 firmo data from sf_account table */
PROC SQL;
CONNECT TO ODBC AS myODBC(datasrc=ICDW_PROD user=DM_GCH password=intercall);
CREATE TABLE SFDC.FIRMODATA_ACCOUNT_FINAL AS
SELECT * FROM CONNECTION TO myODBC
	(SELECT DISTINCT ENTITY_ID__C,
	ACCOUNTNUMBER,
  	NAME,
  	ENTITY_EMPLOYEES__C,
	ENTITY_NAICS__C,
	ENTITY_COUNTRY__C,
	ENTITY_REGION__C,
	NUMBEROFEMPLOYEES,
	NOOFEMPLOYEES__C,
	EMPLOYEE_COUNT__C,
	NAICSCODE,
	NAICSDESC,
	BILLINGCOUNTRY,
	SHIPPINGCOUNTRY,
	ACCOUNT_COUNTRY__C
	HQREGION__C,
	CREATEDDATE
FROM SFDC.SF_ACCOUNT);
QUIT;


/* 4. create 2017,2018,2019,2020 and overall revenue for each company */

PROC SQL;
CREATE TABLE SFDC.ANNUAL_REV AS
	SELECT COALESCE(ENTITY_CODE, COMPANY_ID) AS ENTITY_CODE, ENTITY_NAME, COMPANY_ID, COMPANY_NAME,
	SUM(CASE WHEN YEAR(DATEPART(MONTH_START)) = 2017 THEN USD_REV ELSE 0 END) AS REVENUE_2017,
	SUM(CASE WHEN YEAR(DATEPART(MONTH_START)) = 2018 THEN USD_REV ELSE 0 END) AS REVENUE_2018,
	SUM(CASE WHEN YEAR(DATEPART(MONTH_START)) = 2019 THEN USD_REV ELSE 0 END) AS REVENUE_2019,
	SUM(CASE WHEN YEAR(DATEPART(MONTH_START)) = 2020 THEN USD_REV ELSE 0 END) AS REVENUE_2020,
	SUM(USD_REV) AS TOTAL_REV
	FROM SFDC.FINAL_REV_DATA
	GROUP BY ENTITY_CODE, ENTITY_NAME, COMPANY_ID, COMPANY_NAME;
QUIT;



/*Try another method in getting highest billing company*/
PROC SORT DATA = SFDC.ANNUAL_REV OUT = SFDC.ANNUAL_REV_SORTED;
	BY ENTITY_CODE DESCENDING REVENUE_2019  DESCENDING REVENUE_2020 DESCENDING TOTAL_REV;
RUN;


/*USING FIRST. FUNCTION TO GET THE HIGHEST BILLING COMPANY*/
DATA SFDC.HIGHEST_BILLING;
SET SFDC.ANNUAL_REV_SORTED;
BY ENTITY_CODE;
IF FIRST.ENTITY_CODE THEN OUTPUT;
RUN;

	
/* Joining 3 firmo data at entity level */
PROC SQL;
CREATE TABLE SFDC.FIRMO_ENTITYLEVEL_FINAL AS
	SELECT A.ENTITY_CODE,
			A.ENTITY_NAME,
			A.COMPANY_ID,
			A.COMPANY_NAME,
			B.NO_EMPLOYEES__C AS ENTITY_EE,
			B.NAICS__C AS ENTITY_NAICS,
			B.HQ_COUNTRY__C AS ENTITY_HQ
	FROM SFDC.HIGHEST_BILLING A
	LEFT JOIN SFDC.FIRMODATA_ENTITY B 
		ON A.ENTITY_CODE = B.ENTITY_CODE__C;
QUIT;

/* Joining 3 firmo data at company/account level */
PROC SQL;
CREATE TABLE SFDC.FIRMO_ACCOUNTLEVEL_FINAL AS
	SELECT *
	FROM SFDC.FIRMO_ENTITYLEVEL_FINAL A 
	LEFT JOIN SFDC.FIRMODATA_ACCOUNT_FINAL B 
		ON A.COMPANY_ID = B.ACCOUNTNUMBER;
QUIT;

/* DATA CLEANING --BILLINGCOUNTRY JOIN ON 2-DIGIT COUNTRY CODE */
PROC SQL;
CREATE TABLE SFDC.DATACLEANING1 AS
	SELECT A.*, B.IDNAME
	FROM SFDC.FIRMO_ACCOUNTLEVEL_FINAL A
	LEFT JOIN MAPSGFK.WORLD_ATTR B
	ON A.BILLINGCOUNTRY = B.ID;
QUIT;


DATA SFDC.DATA_CLEANED;
SET SFDC.DATACLEANING1;
LENGTH SA_HQ $ 50;
IF MISSING(BILLINGCOUNTRY) THEN SA_HQ = 'NO COUNTRY';
ELSE IF NOT MISSING(IDNAME) THEN SA_HQ = IDNAME;
ELSE IF MISSING(IDNAME) AND NOT MISSING(BILLINGCOUNTRY) THEN SA_HQ = BILLINGCOUNTRY;
DROP ENTITY_ID__C NAME ACCOUNTNUMBER ENTITY_EMPLOYEES__C ENTITY_NAICS__C ENTITY_COUNTRY__C ENTITY_REGION__C NOOFEMPLOYEES__C EMPLOYEE_COUNT__C SHIPPINGCOUNTRY ACCOUNT_COUNTRY__C HQREGION__C IDNAME;
RUN;


/* Creating consolidated data for employee count, NAICS code and HQ_Country */

/* For employee count, getting the higher number between the employee count in entity level and company level */

DATA SFDC.FINALDATA1;
SET SFDC.DATA_CLEANED;
CONSO_EE = MAX(ENTITY_EE, NumberOfEmployees);
RUN;

/* Getting the first two digits of NAICS code */

DATA SFDC.FINALDATA1;
SET SFDC.FINALDATA1;
X = PUT(ENTITY_NAICS, BEST12. -L);
Y = PUT(NAICSCODE, BEST12. -L);
NAICS2_ENTITY = SUBSTR(X,1,2);
NAICS2_SA = SUBSTR(Y,1,2);
DROP X Y;
RUN;

/* Replacing null values with 0 in NAICS2_ENTITY and NAICS2_SA for analysis */
DATA SFDC.FINALDATA1;
SET SFDC.FINALDATA1;
IF NAICS2_ENTITY = ' ' OR NAICS2_ENTITY EQ . THEN NAICS2_ENTITY = "0";
IF NAICS2_SA = ' ' OR NAICS2_SA EQ . THEN NAICS2_SA = "0";
RUN;

/* Creating the consolidated NAICS2 code */
DATA SFDC.FINALDATA1;
SET SFDC.FINALDATA1;
IF NAICS2_ENTITY = NAICS2_SA THEN CONSO_NAICS2 = NAICS2_ENTITY;
ELSE IF NAICS2_ENTITY = "99" AND NAICS2_SA = "0" THEN CONSO_NAICS2 = "99";
ELSE IF NAICS2_ENTITY <> NAICS2_SA AND (NAICS2_ENTITY = "99" OR NAICS2_ENTITY = "0") AND (NAICS2_SA <> "99" OR NAICS2_SA <> "0") THEN CONSO_NAICS2 = NAICS2_SA;
ELSE CONSO_NAICS2 = NAICS2_ENTITY;
RUN;

/* creating the consolidated HQ country */
DATA SFDC.FINALDATA1;
SET SFDC.FINALDATA1;
LENGTH CONSO_HQ $ 50;
IF ENTITY_HQ = SA_HQ THEN CONSO_HQ = ENTITY_HQ;
ELSE IF MISSING(ENTITY_HQ) OR ENTITY_HQ = 'NO COUNTRY' THEN CONSO_HQ = SA_HQ;
ELSE IF ENTITY_HQ ^= SA_HQ THEN CONSO_HQ = ENTITY_HQ;
RUN;

DATA SFDC.FINALDATA2;
SET SFDC.FINALDATA1;
LENGTH CONSOLIDATED_HQ $ 50;
IF CONSO_HQ = 'HK' THEN CONSOLIDATED_HQ = 'Hong Kong';
ELSE IF CONSO_HQ = 'MO' THEN CONSOLIDATED_HQ = 'Macao';
ELSE IF CONSO_HQ = 'SQ' THEN CONSOLIDATED_HQ = 'Slovakia';
ELSE IF CONSO_HQ = 'UK' THEN CONSOLIDATED_HQ = 'United Kingdom';
ELSE IF CONSO_HQ = 'USA' THEN CONSOLIDATED_HQ = 'United States';
ELSE IF CONSO_HQ = 'XK' THEN CONSOLIDATED_HQ = 'Kosovo';
ELSE CONSOLIDATED_HQ = CONSO_HQ;
DROP CONSO_HQ;
RUN;

/*Pulling the NAICS2 description from GCH_DIM_NAICS table*/

PROC SQL;
CONNECT TO ODBC AS myODBC(datasrc=ICDW_PROD user=DM_GCH password=intercall);
CREATE TABLE SFDC.NAICS2_DESC AS
SELECT * FROM CONNECTION TO myODBC
	(SELECT DISTINCT TO_CHAR(NAICS_2_DIGIT_ID) AS NAICS2_ID, NAICS_2_DIGIT_DESC
	FROM DM_GCH.GCH_DIM_NAICS
	ORDER BY NAICS_2_DIGIT_ID);
QUIT; 

/*Mapping NAICS2 Desc to Conso_NAICS*/
PROC SQL;
CREATE TABLE SFDC.FINALDATA4 AS
	SELECT A.*, B.NAICS_2_DIGIT_DESC
	FROM SFDC.FINALDATA2 A
	LEFT JOIN SFDC.NAICS2_DESC B
	ON A.CONSO_NAICS2 = B.NAICS2_ID;
RUN;

PROC EXPORT DATA = SFDC.FINALDATA4 OUTFILE = 'E:\SASDATA\COrtiz\EC Data\FINALDATA409042020.txt'
	dbms= tab
	replace;
RUN;
