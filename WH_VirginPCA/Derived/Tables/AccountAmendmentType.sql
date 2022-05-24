CREATE TABLE [Derived].[AccountAmendmentType] (
    [AccountAmendmentTypeID]   INT            IDENTITY (1, 1) NOT NULL,
    [AccountAmendmentTypeDesc] NVARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([AccountAmendmentTypeID] ASC)
);

