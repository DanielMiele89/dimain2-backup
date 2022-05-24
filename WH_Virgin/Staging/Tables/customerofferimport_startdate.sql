CREATE TABLE [Staging].[customerofferimport_startdate] (
    [hashKey]        NVARCHAR (50) NULL,
    [fanId]          INT           NULL,
    [slcCustomerId]  NVARCHAR (50) NULL,
    [offerId]        NVARCHAR (50) NULL,
    [offerStartDate] DATETIME2 (7) NULL,
    [endDate]        DATETIME2 (7) NULL
);

