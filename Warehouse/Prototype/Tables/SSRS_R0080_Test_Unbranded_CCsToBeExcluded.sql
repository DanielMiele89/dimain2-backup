CREATE TABLE [Prototype].[SSRS_R0080_Test_Unbranded_CCsToBeExcluded] (
    [ConsumerCombinationID] INT          NOT NULL,
    [MID]                   VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [IDX_CCID]
    ON [Prototype].[SSRS_R0080_Test_Unbranded_CCsToBeExcluded]([ConsumerCombinationID] ASC);

