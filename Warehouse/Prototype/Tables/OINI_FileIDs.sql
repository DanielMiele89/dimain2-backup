CREATE TABLE [Prototype].[OINI_FileIDs] (
    [FileID]               INT NULL,
    [Inserted]             INT NOT NULL,
    [AddedToFinalTable]    BIT NULL,
    [CC_IDUpdated]         BIT NULL,
    [DeletedFromMainTable] BIT NULL,
    [MissingCustomerAdded] BIT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FileMC]
    ON [Prototype].[OINI_FileIDs]([FileID] ASC, [MissingCustomerAdded] ASC);

