CREATE TABLE [Derived].[__Publisher] (
    [ID]            INT          NOT NULL,
    [PublisherName] VARCHAR (50) NOT NULL,
    [ROCStartDate]  DATE         NULL,
    [ROCEndDate]    DATE         NULL,
    CONSTRAINT [PK_Report_Publisher] PRIMARY KEY CLUSTERED ([ID] ASC)
);

