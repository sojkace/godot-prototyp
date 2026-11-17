using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class UiMaster : MonoBehaviour
{
    public static UiMaster instance { get; private set; }
    [Header("UI Elements")]
    [SerializeField]
    private RectTransform buildingUIList;
    [SerializeField]
    private RectTransform buildMenu;
    [SerializeField]
    private RectTransform shopMenu;
    [SerializeField]
    private RectTransform shop;
    [SerializeField]
    private RectTransform marketplace;
    [SerializeField]
    public RectTransform marketplaceCardTable;
    [SerializeField]
    public Transform aktivCardInMP;
    [SerializeField]
    private TMP_Text currentRoundText;
    [SerializeField]
    private TMP_Text currentLevelText;
    [SerializeField]
    private RectTransform itemDeck;

    [Header("Dont Touch")]
    private List<Item> items = new List<Item>();
    private List<BuildingUI> buildings = new List<BuildingUI>();
    private bool buildingUIListOpen = true;
    public List<Item> itemsWantToSwitch = new List<Item>();

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Debug.Log("UiMaster exist more then ones");
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


    public void ToggelBuildingUIList()
    {
        if (buildingUIListOpen)
        {
            buildingUIList.anchoredPosition = new Vector2(-buildingUIList.GetComponent<RectTransform>().sizeDelta.x, 0);
            buildingUIListOpen = false;
        }
        else
        {
            buildingUIList.anchoredPosition = new Vector2(0, 0);
            buildingUIListOpen = true;
        }
    }

    public bool CheckIfMarketplaceIsOpen(Marketplace maketplace)
    {
        if(GameMaster.instance.phase == "nothing")
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    public void SetItemDeck(bool state)
    {
        itemDeck.gameObject.SetActive(state);
    }

    public void SetBuildMenu(bool state)
    {
        buildMenu.gameObject.SetActive(state);
    }

    public void SetShopMenu(bool state)
    {
        shopMenu.gameObject.SetActive(state);
    }

    public void SetShop(bool state)
    {
        shop.gameObject.SetActive(state);
    }

    public void OpenMarketplace(Marketplace marketplaceBuilding)
    {
        if(GameMaster.instance.phase == "nothing")
        {
            GameMaster.instance.phase = "openMP";
            ItemMaster.instance.aktivMarketplace = marketplaceBuilding;
            marketplace.gameObject.SetActive(true);

            foreach (ItemCard itemCard in marketplaceBuilding.itemsInMaketplace)
            {
                itemCard.gameObject.SetActive(true);
            }
        }
    }

    public void CloseMarketplace()
    {

        
        
        marketplace.gameObject.SetActive(false);
        foreach (ItemCard i in ItemMaster.instance.aktivMarketplace.itemsInMaketplace)
        {
            i.gameObject.SetActive(false);
            i.SetInSwitchMode(false);
        }
        GameMaster.instance.phase = "nothing";
        ItemMaster.instance.aktivMarketplace = null;
    }

    public void SetCurrentRound(int currentRound, int maxRound, int currentLevel)
    {
        currentRoundText.text = currentRound.ToString() + "/" + maxRound.ToString();
        currentLevelText.text = currentLevel.ToString();
    }
}
