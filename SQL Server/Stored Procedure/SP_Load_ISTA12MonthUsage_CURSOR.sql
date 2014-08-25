USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[SP_Load_ISTA12MonthUsage_CURSOR]    Script Date: 08/25/2014 12:21:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
02/11/2011			ERIC MCCORMICK				This stored procedure is a CURSOR that reloads the ISTA12MonthUsage table.
08/15/2014			Jide Akintoye				Format Stored Procedure



**********************************************************************************************/


CREATE PROCEDURE [dbo].[SP_Load_ISTA12MonthUsage_CURSOR] ( @DummyInput CHAR(1) )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
-- 	SET ROWCOUNT 1000	
        DECLARE @LDCID INT         -- ISTA LDCID (66-PPL, 61-PECO)
        DECLARE @LoadProfile VARCHAR(100)-- ISTA Load Profile
        DECLARE @MeterNumber VARCHAR(100)-- ISTA Meter Number
        DECLARE @RateClass VARCHAR(100)-- ISTA Rate Class
        DECLARE @PremNo VARCHAR(100)-- ISTA Premise Number
        DECLARE @CapacityObligation VARCHAR(100)-- From view dbo.vPACustomerInfo
        DECLARE @WSMeterNumber VARCHAR(100)-- ISTA Premise Number working storage
        DECLARE @Quantity INT			-- ISTA Usage Quantity
        DECLARE @ServicePeriodStart DATETIME	-- ISTA Service Period Start
        DECLARE @WSCounter INT			-- Working Storage Counter
        DECLARE @CompositeUOM VARCHAR(10) -- Values are (K1-KWH, KH-Kilo Watts per Month)
	
        DECLARE ISTA_Usage_CURSOR CURSOR
        FOR
            SELECT  DISTINCT
                    P.LDCID ,
                    S.LoadProfile ,
                    S.MeterNumber ,
                    S.RateClass ,
                    P.PremNo ,
                    vPA.CapacityObligation ,
                    t867NIS.ServicePeriodStart ,
                    t867NIS.Quantity ,
                    t867NIS.CompositeUOM
            FROM    Stream.dbo.Customer AS C
            INNER JOIN Stream.dbo.Premise AS P ON C.CustID = P.CustID
                                                  AND P.STATUSID IN ( '1' ,
                                                              '5' , '7' , '8' ,
                                                              '9' , '10' )
            INNER JOIN ( SELECT S.EsiId ,
                                M.RateClass ,
                                M.LoadProfile ,
                                M.MeterNumber
                         FROM   StreamMarket.dbo.tbl_814_Header AS H
                         INNER JOIN StreamMarket.dbo.tbl_814_Service AS S ON S.[814_Key] = H.[814_Key]
                         INNER JOIN StreamMarket.dbo.tbl_814_Service_Meter AS M ON M.Service_Key = S.Service_Key
                         WHERE  ( H.TdspDuns NOT IN ( '006917090' ,
                                                      '006917967' ) )
                                AND ( H.ActionCode = 'E' )
                                AND ( H.Direction = 1 )
                       ) AS S ON S.EsiId = P.PremNo
            INNER JOIN StreamMarket.dbo.tbl_867_Header t867H ON s.EsiId = t867H.EsiId
            INNER JOIN StreamMarket.dbo.tbl_867_NonIntervalSummary t867S ON t867h.[867_Key] = t867s.[867_Key]
            INNER JOIN StreamMarket.dbo.tbl_867_NonIntervalSummary_Qty t867NIS ON t867s.NonIntervalSummary_Key = t867NIS.NonIntervalSummary_Key
                                                              AND t867NIS.CompositeUOM = 'KH'
            INNER JOIN StreamInternal.dbo.vPACustomerInfo vPA ON vPA.PremNo = P.PremNo
            ORDER BY
					--S.LoadProfile,
                    S.MeterNumber ,
					--S.RateClass,
                    P.PremNo ,
                    t867NIS.ServicePeriodStart DESC
					
	-- Empty the target table.
        TRUNCATE TABLE StreamInternal.dbo.ISTA12MonthUsage 
	
	-- Seed CURSOR
        OPEN ISTA_Usage_CURSOR   
        FETCH NEXT FROM ISTA_Usage_CURSOR INTO @LDCID , @LoadProfile ,
            @MeterNumber , @RateClass , @PremNo , @CapacityObligation ,
            @ServicePeriodStart , @Quantity , @CompositeUOM
        SET @WSMeterNumber = @MeterNumber
        SET @WSCounter = 1

	-- Loop through CURSOR
        WHILE @@FETCH_STATUS = 0
            BEGIN   
			
                IF @WSMeterNumber <> @MeterNumber
                    BEGIN
                        INSERT  INTO StreamInternal.dbo.ISTA12MonthUsage
                        VALUES  ( @LDCID , @LoadProfile , @MeterNumber ,
                                  @RateClass , @PremNo , @CapacityObligation ,
                                  @Quantity , @ServicePeriodStart ,
                                  @CompositeUOM , 'SP_Load_ISTA12MonthUsage' ,
                                  GETDATE() )
                        SET @WSMeterNumber = @MeterNumber
                        SET @WSCounter = 0
                    END
                ELSE
                    BEGIN
                        IF @WSCounter < 11
                            BEGIN
                                SET @WSCounter = @WSCounter + 1
                                INSERT  INTO StreamInternal.dbo.ISTA12MonthUsage
                                VALUES  ( @LDCID , @LoadProfile , @MeterNumber ,
                                          @RateClass , @PremNo ,
                                          @CapacityObligation , @Quantity ,
                                          @ServicePeriodStart , @CompositeUOM ,
                                          'SP_Load_ISTA12MonthUsage' ,
                                          GETDATE() )
                            END
                        ELSE
                            BEGIN
                                SET @WSCounter = @WSCounter + 1
                            END
                    END
			-- Get Next Record	
                FETCH NEXT FROM ISTA_Usage_CURSOR INTO @LDCID , @LoadProfile ,
                    @MeterNumber , @RateClass , @PremNo , @CapacityObligation ,
                    @ServicePeriodStart , @Quantity , @CompositeUOM
            END   
		
        CLOSE ISTA_Usage_CURSOR   
        DEALLOCATE ISTA_Usage_CURSOR  
    END









GO


