CREATE TABLE [Staging].[RetailerCustomersExposedMonth] (
    [ID]            INT  IDENTITY (1, 1) NOT NULL,
    [RetailerID]    INT  NOT NULL,
    [MonthDate]     DATE NOT NULL,
    [CustomerCount] INT  NOT NULL,
    CONSTRAINT [PK_Staging_RetailerCustomersExposedMonth] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UC_RetailerCustomersExposedMonth] UNIQUE NONCLUSTERED ([RetailerID] ASC, [MonthDate] ASC)
);

