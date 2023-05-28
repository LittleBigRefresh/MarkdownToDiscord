namespace MarkdownToDiscord.Elements;

public class HeaderMarkdownElement : TextMarkdownElement
{
    public readonly int Depth;
    
    public HeaderMarkdownElement(int depth, string text) : base(text)
    {
        this.Depth = depth;
    }
}