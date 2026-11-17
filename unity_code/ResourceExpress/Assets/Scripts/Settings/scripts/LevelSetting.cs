using System.Collections.Generic;
using Unity.VisualScripting.FullSerializer;
using UnityEngine;

[CreateAssetMenu]
public class LevelSetting : ScriptableObject
{
    public List<RoundSettings> roundSettings;
    public List<Card> attackDeck;
    public List<Card> railDeck;
    public List<Card> specialDeck;
    public List<ItemSettings> itemcards;
    
}

[System.Serializable]
public struct ItemSettings
{
    public int num;
    public ItemCard itemCard;
}
