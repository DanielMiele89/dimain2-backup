CREATE TABLE [Staging].[ExceptionList] (
    [BrandID]          INT          NULL,
    [MerchantID]       VARCHAR (15) NULL,
    [TransactionText]  VARCHAR (22) NULL,
    [AgreedBy]         VARCHAR (14) NOT NULL,
    [Note]             VARCHAR (17) NOT NULL,
    [CheckWithPartner] VARCHAR (3)  NOT NULL,
    [ActiveFromDate]   DATE         NULL,
    [ActiveToDate]     DATE         NULL
);

