CREATE TABLE [Selections].[LE029_PreSelection_Bottom] (
    [FanID] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [Selections].[LE029_PreSelection_Bottom]([FanID] ASC);

