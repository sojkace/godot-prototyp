using System.Collections.Generic;
using UnityEngine;

public class GameMaster : MonoBehaviour
{
    public static GameMaster instance {  get; private set; }

    private Building dirtPrefab;
    private Building flagNormalPrefab;
    private Building flagPointyPrefab;
    private Building mineGoldPrefab;
    private Building mineSilverPrefab;
    private Building powerStationPrefab;
    private Building railCurvePrefab;
    private Building railStraitPrefab;
    private Building watherPrefab;

    [Header("Game Settings")]
    [SerializeField]
    private List<LevelSetting> levelSettings;

    [Header("Important Instance")]


    [Header("Dont Touch")]
    public string phase;

    public LevelSetting currentLevel;
    private RoundSettings currentRound;
    private Grid grid;

    private void Awake()
    {
        if(instance != null && instance != this)
        {
            Debug.Log("GameMaster exist more then ones");
            Destroy(this);
        }
        else
        {
            instance = this;
        }

        dirtPrefab = BuildingMaster.instance.dirtPrefab;
        flagNormalPrefab = BuildingMaster.instance.flagNormalPrefab;
        flagPointyPrefab = BuildingMaster.instance.flagPointyPrefab;
        mineGoldPrefab = BuildingMaster.instance.mineGoldPrefab;
        mineSilverPrefab = BuildingMaster.instance.mineSilverPrefab;
        powerStationPrefab = BuildingMaster.instance.powerStationPrefab;
        railCurvePrefab = BuildingMaster.instance.railCurvePrefab;
        railStraitPrefab = BuildingMaster.instance.railStraitPrefab;
        watherPrefab = BuildingMaster.instance.watherPrefab;

        grid = BuildingMaster.instance.grid;
    }
    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = 60;
        StartGame();
    }

    // Update is called once per frame
    void Update()
    {

    }

    //start game: generat Island
    public void StartGame()
    {
        currentLevel = levelSettings[0];
        currentRound = currentLevel.roundSettings[0];
        //UiMaster.instance.SetCurrentRound(currentRound, currentLevel.numberOfRounds, currentLevel.level);
        LoadLevel(currentLevel);
        IslandBuilder.instance.GenerateIsland();

    }


    public void StartTrain()
    {
        if(phase == "nothing")
        {
            TrainMaster.instance.StartTrain(currentRound.trains);
        }

    }

    public void NextRound()
    {
        foreach(Building b in BuildingMaster.instance.buildings)
        {
            b.NextRound();
        }
        int indexOfCurrentRound = currentLevel.roundSettings.IndexOf(currentRound);

        if(indexOfCurrentRound == currentLevel.roundSettings.Count - 1)
        {
            NextLevel();
        }
        else
        {
            currentRound = currentLevel.roundSettings[indexOfCurrentRound + 1];
        }

        ItemMaster.instance.StartItemCrafter();
        //UiMaster.instance.SetCurrentRound(currentRound, currentLevel.numberOfRounds, currentLevel.level);
    }

    private void NextLevel()
    {
        int indexOfCurrentLevel = levelSettings.IndexOf(currentLevel);
        currentLevel = levelSettings[indexOfCurrentLevel++];
        currentRound = currentLevel.roundSettings[0];
        LoadLevel(currentLevel);
    }

    public void LoadLevel(LevelSetting level)
    {
        CardMaster.instance.SetUpCards(level.attackDeck, level.railDeck, level.specialDeck);
        ItemMaster.instance.SetUpItems(level.itemcards);

    }

}


