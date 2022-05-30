CREATE TABLE [Processing].[Masking_NameDictionary] (
    [Unmasked]   VARCHAR (50) NULL,
    [isLastName] INT          NULL,
    [LightMask]  VARCHAR (50) NULL,
    [HeavyMask]  VARCHAR (50) NULL,
    [NameLen]    INT          NULL
);


GO
CREATE CLUSTERED INDEX [cx_Stuff]
    ON [Processing].[Masking_NameDictionary]([isLastName] ASC, [Unmasked] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated Staging table table that holds UNION ALL of DISTINCT First Names and Last Names with a length >= 5 from Relational.Customer that have not been exempted', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_NameDictionary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The unmasked name', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_NameDictionary', @level2type = N'COLUMN', @level2name = N'Unmasked';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifies whether a name is a Last Name (if it is not, it is a First Name)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_NameDictionary', @level2type = N'COLUMN', @level2name = N'isLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The light mask version of a name', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_NameDictionary', @level2type = N'COLUMN', @level2name = N'LightMask';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The heavy masked version of the name', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_NameDictionary', @level2type = N'COLUMN', @level2name = N'HeavyMask';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The length of the name', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Masking_NameDictionary', @level2type = N'COLUMN', @level2name = N'NameLen';

