using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ItemMaster : MonoBehaviour
{
    public static ItemMaster instance { get; private set; }

    [Header("Prefabs")]
    [SerializeField]
    public List<Item> itemsPrefab = new List<Item>();

    [Header("Holder")]
    [SerializeField]
    public Transform itemHolder;
    [SerializeField]
    public Transform itemCardHolder;

    [Header("Dont Touch")]
    public Marketplace aktivMarketplace;
    private List<ItemCard> itemCards = new List<ItemCard>();
    private List<Item> items = new List<Item>();
    public List<ItemCard> itemsWantToSwitch = new List<ItemCard>();
    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Debug.Log("ItemMaster exist more then ones");
            Destroy(this);
        }
        else
        {
            instance = this;
        }
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetUpItems(List<ItemSettings> itemSettings)
    {
        itemCards.Clear();
        foreach(ItemSettings itemSetting in itemSettings)
        {
            for (int i = itemSetting.num; i > 0; i--)
            {
                itemCards.Add(itemSetting.itemCard);
            }
        }
        itemCards = ShuffleDeck(itemCards);
    }

    public void StartItemCrafter()
    {
        int numOfItems = 0;
        foreach (Building b in BuildingMaster.instance.buildings)
        {
            if (b.type == "ItemCrafter")
            {
                numOfItems++;
                //b.GetComponent<Itemcrafter>().SetCollectIconAnimation(true);

            }
        }

        
        for (int i = numOfItems * 2; i > 0; i--)
        {
            ItemCard newItemCard = Instantiate(itemCards[0], itemCardHolder);
            newItemCard.SetUp(itemCards[0], "Deck");
            itemCards.Remove(itemCards[0]);
            
        }

        UiMaster.instance.SetItemDeck(true);

    }


    public List<ItemCard> ShuffleDeck(List<ItemCard> deck)
    {
        for (int i = deck.Count - 1; i > 0; i--)
        {
            int j = Random.Range(0, i + 1);
            ItemCard temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }
        return deck;
    }

    public void AddItem(string type)
    {
        foreach (Item itemUi in itemsPrefab)
        {
            if (type == itemUi.type)
            {

                Item item = GetItemOfTyp(type);

                if (item != null)
                {
                    item.AddItemOfThisType(1);
                }
                else
                {
                    Item newItem = Instantiate(itemUi, itemHolder);
                    items.Add(newItem);
                    newItem.SetUp(1, "Inventory");
                }


                CardMaster.instance.UpdateTable();
            }
        }
    }

    public void AddNewItemsInMarketplace(Marketplace marketplace, int num)
    {
        foreach(ItemCard itemCard in marketplace.itemsInMaketplace)
        {
            Debug.Log("Test");
            itemCards.Add(itemCard.prefabeOfCard);
            Destroy(itemCard.gameObject);
        }
        marketplace.itemsInMaketplace.Clear();
        itemCards = ShuffleDeck(itemCards);
        Debug.Log(UiMaster.instance.marketplaceCardTable.transform.GetChild(0));
        for (int i = 0; i < num; i++)
        {
            ItemCard newItemCard = Instantiate(itemCards[0], UiMaster.instance.marketplaceCardTable.transform.GetChild(i));
            newItemCard.SetUp(itemCards[0], "Marketplace");
            itemCards.Remove(itemCards[0]);
            newItemCard.gameObject.SetActive(false);
            marketplace.itemsInMaketplace.Add(newItemCard);
        }
    }

    public void SwitchItemsFromMP(ItemCard itemCard, Item item)
    {
        ItemMaster.instance.AddItem(itemCard.type);
        ItemMaster.instance.RemoveItem(item.type, 1);

        itemCard.SetInSwitchMode(false);
        int childIndex = itemCard.transform.parent.GetSiblingIndex();
        aktivMarketplace.itemsInMaketplace.Remove(itemCard);
        Destroy(itemCard.gameObject);

        ItemCard newPreItemCard = null;
        foreach (ItemSettings itemSetting in GameMaster.instance.currentLevel.itemcards)
        {
            if(itemSetting.itemCard.type == item.type)
            {
                newPreItemCard = itemSetting.itemCard;
            }
        }
        ItemCard newItemCard = Instantiate(newPreItemCard, UiMaster.instance.marketplaceCardTable.transform.GetChild(childIndex));
        newItemCard.SetUp(itemCards[0], "Marketplace");
        aktivMarketplace.itemsInMaketplace.Add(newItemCard);
        aktivMarketplace.SetState(false);

    }

    // return the item of given type
    private Item GetItemOfTyp(string type)
    {
        Item item = null;
        foreach (Item i in items)
        {
            if (type == i.type)
            {
                item = i;
            }

        }
        return item;
    }

    public void AddRandomItem()
    {
        string type = itemsPrefab[Random.Range(0, itemsPrefab.Count)].type;
        foreach (Item itemUi in itemsPrefab)
        {
            if (type == itemUi.type)
            {

                Item item = GetItemOfTyp(type);

                if (item != null)
                {
                    item.AddItemOfThisType(1);
                }
                else
                {
                    Item newItem = Instantiate(itemUi, itemHolder);
                    items.Add(newItem);
                    newItem.SetUp(1, "Inventory");
                }


                CardMaster.instance.UpdateTable();
            }
        }
    }

    public int GetAmountOfItemsOfType(Resources resource)
    {
        int amount = 0;
        foreach (Item i in items)
        {
            if (resource.type == i.type)
            {
                amount = i.number;
            }
        }

        return amount;
    }

    public void RemoveItem(string type, int number)
    {

        foreach (Item item in items)
        {
            if (item.type == type)
            {
                item.RemoveItemOfThisType(number);
                if (item.number <= 0)
                {
                    items.Remove(item);
                    Destroy(item.gameObject);
                    break;
                }
            }
        }

    }

}
