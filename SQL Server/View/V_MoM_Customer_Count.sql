Create View dbo.v_CP_MoM_Customer_Count
As
With StartofMonthCustCount
AS
( 

SELECT 
		CONVERT(date,CalendarDate) as 'CalendarDate',
		State,
		SUM(CustCount) as 'CustCount',
		LEFT(CONVERT(varchar, DATEADD(D,-1,CalendarDate),112),6) as 'Date'--20140401 is for the end of March 2014, so the date is 201403
		FROM StreamInternal.dbo.CP_Customer_Count
		WHERE CalendarDate =	DATEADD(month, DATEDIFF(month, 0, CalendarDate), 0)--only get the first of the month
		GROUP BY  CONVERT(date,CalendarDate),
		State,
			CalendarDate
)
,   
--Get the gains and losses for each month
--Don't think the net gain field is necessary... whatever
GainLoss
AS
(
SELECT
	 LEFT(CONVERT(varchar, cp.CalendarDate,112),6) as 'Date',
	 State,
	 SUM(GainCount) as 'Gain',
	 SUM(LossCount) as 'Loss',
	 SUM(GainCount) - SUM(LossCount) as 'NetGain'
FROm StreamInternal.dbo.CP_Customer_Count CP
Where CalendarDate <= GETDATE()
      GROUP BY LEFT(CONVERT(varchar, CalendarDate,112),6), 
               State
               )

SELECT
	 s.CalendarDate,
	 s.State,
	 s.CustCount,
	 g.Gain,
	 g.Loss,
	 g.NetGain
FROM StartofMonthCustCount s
 LEFT JOIN GainLoss g ON g.State = s.State
                            AND s.Date = g.Date
WHERE convert(int,s.Date) < convert(int,LEFT(CONVERT(varchar, GETDATE(),112),6))	 --we don't want to show the most recent month because we don't have the run from the first of next month yet 
        AND s.CalendarDate >= DATEADD(m,-18,GETDATE()) --and s.state ='TX'