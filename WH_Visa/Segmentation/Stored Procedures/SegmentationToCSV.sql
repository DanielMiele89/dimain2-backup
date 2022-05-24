/*

*/
CREATE PROCEDURE [Segmentation].[SegmentationToCSV]
AS
BEGIN


EXECUTE sp_execute_external_script 
    @language = N'Python'
    , @script = N'

import pandas as pd
from rwrd_custom_logger import CustomLogger
from datetime import datetime


date = datetime.today().strftime(''%Y-%m-%d'')

res = InputDataSet

size = 5000000

df = pd.DataFrame.from_records(res, columns=[''ID'', ''CustomerGUID'' ,''HydraOfferID'', ''StartDate'', ''EndDate''])


list_of_dfs = [df.loc[i:i+size-1,:] for i in range(0, len(df),size)]

bucketNumber = 1

newpath = ''E:\DataOpsFunctions\PythonOutputs\Segmentation\Visa''

#export the bucket to csv
for i in list_of_dfs:
    df1 = pd.DataFrame(i)

    df1.to_csv(newpath+''\Visa - ''+ str(date)+ '' - '' +str(bucketNumber)+''.csv'', index=False)
    bucketNumber = bucketNumber + 1


'
	, @input_data_1 = N'SELECT	NEWID() AS ID
		,	cu.CustomerGUID
		,	iof.HydraOfferID
		,	convert(varchar, oma.StartDate, 126) AS StartDate
		,	convert(varchar, oma.EndDate, 126)  AS EndDate
	FROM [Segmentation].[OfferMemberAddition] oma
	INNER JOIN [Derived].[IronOffer] iof
		ON oma.IronOfferID = iof.IronOfferID
	INNER JOIN [WHB].[Customer] cu
		ON oma.CompositeID = cu.CompositeID
	where oma.startDate > GETDATE()
	ORDER BY oma.StartDate'



END


