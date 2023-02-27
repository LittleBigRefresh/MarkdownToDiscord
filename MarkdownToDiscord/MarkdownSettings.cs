namespace MarkdownToDiscord;

public class MarkdownSettings
{
    public ulong ChannelId { get; set; }
    public bool ShouldDeleteExistingContents { get; set; } = true;
}