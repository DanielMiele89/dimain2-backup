CREATE TABLE [MI].[jasonTest] (
    [testID]    INT          IDENTITY (1, 1) NOT NULL,
    [test_text] VARCHAR (50) NOT NULL,
    [test_bool] BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([testID] ASC)
);

