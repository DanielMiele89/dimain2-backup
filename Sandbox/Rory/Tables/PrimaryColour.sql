CREATE TABLE [Rory].[PrimaryColour] (
    [PrimaryID]  INT         NOT NULL,
    [PrimaryHex] VARCHAR (7) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_PrimaryID]
    ON [Rory].[PrimaryColour]([PrimaryID] ASC) WITH (FILLFACTOR = 70);

