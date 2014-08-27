USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_TX_Customers]    Script Date: 08/26/2014 15:10:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Eric McCormick						Customer extract from ISTA for use by the Wholesale Trade Application (WTA).
						& Preetha Sridhar					This view matches the layout of the CIS1 CustomerStats table layout.
															Development Notes:	
															The WTA application will most likely be retired by the end of 2013
															which will be prior to the migration of CIS1 Texas customers to ISTA
															making this view unnecessary.  
															This wasn't the case when the view was created! :)
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_ISTA_TX_Customers]
AS
    SELECT  C.ContractID AS ContractID ,				--"CONTRACT_ID" VARCHAR2(7), 
            C.CustNo AS CustomerNumber ,			--"CUSTOMER_NUMBER" VARCHAR2(10) NOT NULL ENABLE, 
            C.CustName AS AccountName ,				--"ACCOUNT_NAME" VARCHAR2(100), 
            C.PremNo AS ESIID ,					--"ESIID" VARCHAR2(100) NOT NULL ENABLE, 
            CASE WHEN PremiseStatus = 'Active' THEN '04'
                 ELSE '00'
            END AS ESIIDStatus ,				--"ESIID_STATUS" CHAR(2) NOT NULL ENABLE, 
            'E' AS ServiceType ,				--"SERVICE_TYPE" CHAR(1), 
            0 AS HistUsghAvg ,				--"HIST_USGH_AVERAGE" NUMBER, 
            C.DUNS AS TDSPDUNS ,				--"TDSP_DUNS" VARCHAR2(20) NOT NULL ENABLE, 
            C.EffectiveDate AS ContractEffectiveDate ,	--"CONTRACT_EFFECTIVE_DATE" DATE, 
            ISNULL(DATEDIFF(m , C.EffectiveDate , C.ExpirationDate) , 0) AS ContractLength ,			--"CONTRACT_LENGTH" NUMBER NOT NULL ENABLE, 
            C.BeginServiceDate AS StartDate ,				--"START_DATE" DATE, 
            C.EndServiceDate AS EndDate ,					--"END_DATE" DATE, 
            C.ProductID AS ProductID ,				--"PRODUCT_ID" CHAR(2), 
            C.ProductCode AS ProductCode ,				--"PRODUCT_CODE" VARCHAR2(40), 
            CASE WHEN C.PlanType = 'FIXED' THEN 'TERM'
                 ELSE 'M2M'
            END AS CustomerType ,			--"CUSTOMER_TYPE" CHAR(4) NOT NULL ENABLE, 
            C.Price AS PriceCharged ,			--"PRICE_CHARGED" NUMBER(10,4), 
            SUBSTRING(C.CustType , 1 , 1) AS PremiseType ,				--"PREMISE_TYPE" CHAR(1), 
            CASE WHEN SUBSTRING(C.CustType , 1 , 1) = 'R' THEN '01'
                 ELSE '02'
            END AS PremiseTypeCode ,			--"PREMISE_TYPE_CODE" CHAR(2) NOT NULL ENABLE, 
            C.ERCOTProfile AS ProfileType ,				--"PROFILE_TYPE" VARCHAR2(30), 
            C.StationCode AS StationCode ,				--"STATION_CODE" VARCHAR2(10), 
            C.WeatherZoneCode AS WeatherStationName ,		--"WEATHER_STATION_NAME" VARCHAR2(10), 
            C.LoadZoneCode AS CMZ ,                     --"CMZ" VARCHAR2(10), 
            C.LoadProfile AS Profile ,					--"PROFILE" VARCHAR2(20), 
            '00' AS LDCRateClass ,			--"LDC_RATE_CLASS" VARCHAR2(30), 
            '0' AS LDCRateSubclass ,			--"LDC_RATE_SUBCLASS" VARCHAR2(10), 
            '0' AS Unmetered ,				--"UNMETERED" CHAR(1), 
            '00' AS UnmeteredProductType ,	--"UNMETERED_PRODUCT_TYPE" CHAR(2), 
            0 AS NumberOfUnits ,			--"NUMBER_OF_UNITS" NUMBER, 
            0 AS QuantityPerDevice ,		--"QUANTITY_PER_DEVICE" NUMBER, 
            'XX' AS RowKey ,					--"ROW_KEY" VARCHAR2(100), 
            'v_ISTA_Customer_Stats' AS RecCreatedBy ,			--"REC_CREATED_BY" VARCHAR2(100), 
            GETDATE() AS RecCreatedDate ,			--"REC_CREATED_DATE" DATE, 
            'v_ISTA_Customer_Stats' AS RecLastUpdatedBy ,		--"REC_LAST_UPDATED_BY" VARCHAR2(100), 
            GETDATE() AS RecLastUpdatedDate		--"REC_LAST_UPDATED_DATE" DATE
    FROM    v_ISTA_Customers C
    WHERE   C.LDCID IN ( 1 , 2 , 3 , 4 , 5 )




GO


