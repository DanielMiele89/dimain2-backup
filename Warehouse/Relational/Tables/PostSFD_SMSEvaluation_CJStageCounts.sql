CREATE TABLE [Relational].[PostSFD_SMSEvaluation_CJStageCounts] (
    [TableName]             VARCHAR (34) NOT NULL,
    [ClubID]                VARCHAR (50) NULL,
    [Shortcode]             VARCHAR (2)  NULL,
    [Pending]               VARCHAR (23) NOT NULL,
    [Available]             VARCHAR (23) NOT NULL,
    [CustomerCount]         INT          NOT NULL,
    [DistinctCustomerCount] INT          NOT NULL,
    [Problems]              VARCHAR (3)  NOT NULL
);

