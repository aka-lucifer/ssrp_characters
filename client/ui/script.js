const center_x = 117.3;
const center_y = 172.8;
const scale_x = 0.02072;
const scale_y = 0.0205;

CUSTOM_CRS = L.extend({}, L.CRS.Simple, {
  projection: L.Projection.LonLat,
  scale: function(zoom) {
    return Math.pow(2, zoom);
  },

  zoom: function(sc) {
    return Math.log(sc) / 0.6931471805599453;
  },

	distance: function(pos1, pos2) {
    var x_difference = pos2.lng - pos1.lng;
    var y_difference = pos2.lat - pos1.lat;
    return Math.sqrt(x_difference * x_difference + y_difference * y_difference);
  },
	transformation: new L.Transformation(scale_x, center_x, -scale_y, center_y), infinite: true
});

const redPoint = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

var bluePoint = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const home = new L.Icon({
  iconUrl: "assets/blips/house.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
})

const Characters = new Vue({
  el: "#Characters-Container",
  vuetify: new Vuetify(),
  data: {
    // Important Data
    resource: "lx_characters",

    // Character Data
    availableSlots: 15,
    characterIndex: -1,

    // Strings
    loadingState: null,
    message: "",

    // Arrays
    registeredCharacters: [],

    // Objects
    selectedCharacter: {},

    // Booleans
    loading: false,
    showCharacters: false,

    // Rules
    nameRules: [
      (v) => !!v || "Name required",
      (v) => (!!v && v.split(' ').length <= 1) || 'No spaces allowed',
      (v) => !!v && v.length <= 50 || "Name must be 50 characters or less",
      (v) => !!v && RegExp("^[a-z A-Z]+$").test(v) || "Invalid Characters",
      (v) => !!v && v.length >= 3 || "Name must be 3 - 50 characters"
    ],
      
    nationalityRules: [
      (v) => !!v || "Nationality required",
      (v) => !!v && v.length <= 50 || "Nationality must be 50 characters or less",
      (v) => !!v && RegExp("^[a-z A-Z]+$").test(v) || "Invalid Characters",
      (v) => !!v && v.length >= 3 || "Nationality must be 3 - 50 characters"
    ],
      
    backstoryRules: [
      (v) => !!v || "Backstory required",
      (v) => !!v && v.length > 10 || "Backstory must be greater than 10 characters"
    ],

    // New Char Data
    showCreator: false,
    creatorMenu: null,
    charName: null,
    charSurname: null,
    charNationality: null,
    charBackstory: null,
    charDob: (new Date(Date.now() - (new Date()).getTimezoneOffset() * 60000)).toISOString().substr(0, 10),
    isFemale: false,

    // Editor Form
    newCharData: {},
    editorMenu: null,
    showEditor: false,

    // Delete Form
    deleteCheck: false,

    // Apartment Data
    defaultApartments: [],
    showApartments: false,
    selectedApartment: {},

    // Disconnect Form
    disconnectOption: false,

    // Map Data
    sateliteStyle: L.tileLayer('assets/mapStyles/styleSatelite/{z}/{x}/{y}.jpg', {minZoom: 0,maxZoom: 8,noWrap: true,continuousWorld: false,attribution: 'Sunstone RP Spawn Chooser',id: 'SateliteStyle map'}),
    atlasStyle: L.tileLayer('assets/mapStyles/styleAtlas/{z}/{x}/{y}.jpg', {minZoom: 0,maxZoom: 5,noWrap: true,continuousWorld: false,attribution: 'Sunstone RP Spawn Chooser',id: 'styleAtlas map'}),

    // Icon Groups
    groups: {
      "Police": L.layerGroup(),
      "General": L.layerGroup()
    },

    // Map
    showMap: false,
    map: null,
    layerController: null,

    // Location UI
    showLocation: false,
    selectedItem: -1,
    selectedLocation: {},
    markers: null,
    locations: [
      {label: "Maze Bank Arena", position: [-826.829268, -70.282336], spawn: [-248.47, -2029.25, 29.94, 227.17], type: "general", img: "assets/img/locations/maze_arena.png", information: "This building is home of the city's basketball team the Los Santos Panic, and where the auditions for the reality show Fame or Shame are held. The stadium is presumed to have sold the naming rights to Maze Bank, which also owns the Maze Bank Tower."},
      {label: "Sandy Shores Sheriff Station", position: [3686.890244, 1834.580116], spawn: [1853.28, 3701.83, 34.27, 94.86], type: "police", img: "assets/img/locations/bcso.jpg", information: "The Sandy Shores Sheriff's Station is a sheriff station in Blaine County, located in the same building as the Sandy Shores Medical Center, on Alhambra Drive in Sandy Shores."},
      {label: "Bolingbroke Penitentiary", position: [2593.902439, 1674.710425], spawn: [1849.89, 2586.54, 45.67, 260.29], type: "general", img: "assets/img/locations/bolingbroke.png", information: "Bolingbroke Penitentiary is the state prison of San Andreas, it is governed by the San Andreas State Prison Authority. The prison is located on the Los Santos County side of Route 68, just down the road from Harmony. The prison's shape is that of an octagon.<br><br>The perimeter of the prison is patrolled by the Blaine County Sheriff's Office and the Los Santos Police Department. There are armed San Andreas State Prison Authority officers standing near the entrances, making sure that no one attempts to break in or out."},
      {label: "Luxury Autos", position: [-1108.841463, -40.118243], spawn: [-10.63, -1095.95, 26.67, 174.59], type: "general", img: "assets/img/locations/luxury_autos.jpg", information: "Luxury Autos is an auto dealership, that sells Buckingham, Pfister, Grotti, Enus and Pegassi vehicles, as noticeable on the windows of the building. On display in the windows are studio lights, a curtain, a color chart and two unidentified Grotti and Pegassi sheet-covered vehicles."},
      {label: "Pinkcage Motel", position: [-12.804878, 231.358591], spawn: [324.36, -231.01, 54.22, 124.99], type: "general", img: "assets/img/locations/pinkcage.png", information: "The Pink Cage Motel is a motel on the intersection of Hawick Avenue and Meteor Street, opposite of a Fleeca Bank in Alta, Los Santos.<br><br>The business offers thirty-seven air-conditioned rooms with color televisions. Residents also have access to a fenced full-length swimming pool from twelve to nine.<br><br>According to a sign at the entrance to the building, prostitution, visitors and food or drinks within the area of the pool are prohibited."},
      {label: "Vespucci Police Station", position: [-1983.841463, -317.627896], spawn: [-1051.32, -833.83, 19.2, 327.81], type: "police", img: "assets/img/locations/vespucci_pd.png", information: "This police station serves the district of Vespucci in west Los Santos. It is bordered by San Andreas Avenue, South Rockford Drive and Vespucci Boulevard.<br><br>The Vespucci Police Station is a modern three-story building which is based on the real life Santa Monica Public Safety Facility. Like other police stations in the game, it serves as a respawn point if the player is busted in the area."},
      {label: "San Andreas Highway Patrol", position: [6040.54878, -433.759653], spawn: [1564.3, 876.33, 77.48, 158.64], type: "police", img: "assets/img/locations/sahp.jpg", information: "The San Andreas Highway Patrol station is located on the intersection of Paleto Boulevard and Route 1 in Paleto Bay."},
      {label: "Beeker's Garage", position: [6665.54878, 122.767857], spawn: [104.93, 6613.69, 32.4, 217.37], type: "general", img: "assets/img/locations/paleto_garage.jpg", information: "Beeker's Garage is an independent vehicle customization and repair shop in Paleto Bay.<br><br>It is the only tuning shop in northern Blaine County, located within the Paleto Bay Rest Stop in Paleto Bay. Functionally, Beeker's Garage is identical to Los Santos Customs, having the same customization options and the same prices."},
      {label: "LS International Airport", position: [-2796.341463, -1050.615347], spawn: [-1042.36, -2745.42, 21.36, 316.02], type: "general", img: "assets/img/locations/lsia.jpg", information: "Los Santos International Airport (LSIA) is an international airport located in the city of Los Santos, San Andreas, located to the west of the port and to the south of La Puerta.<br><br>The airport consists of four main terminals, two in the south and two in the west, and three runways. There are two access roads looping through all of the main terminals, arrivals at the bottom and departures on top, an arrangement common in most real-life international airports.<br><br>LSIA is connected to Interstate 5, albeit indirectly through an exit at La Puerta and South Los Santos. It also connects the Port of LS through a side road at the northeast. It is connected to the Los Santos Transit with bus stops on access roads and two metro stations."},
      {label: "Del Perro Pier", position: [-1223.170732, -1827.340734], spawn: [-1625.97, -1008.97, 13.11, 31.4], type: "general", img: "assets/img/locations/pier.png", information: "Del Perro Pier is, as its name suggests, located in Del Perro, Los Santos. It is mainly accessed through Red Desert Avenue. Del Perro Pier is renowned for its bright, vivid colors that shine at night, giving the surrounding beaches a sort of vibe.<br><br>The pier is home to many attractions. At the end of the pier is a viewing area where one can look at the Pacific Ocean through a Telescope. Throughout the pier, there are several different restaurants and shops, including a parking lot on the pier itself.<br><br>Towards the centre of the Del Perro Pier is an amusement park known as Pleasure Pier. It is most well-known for its ferris wheel and roller coaster that emit bright flashing lights at night.<br><br>There are also vending machines nearby that help replenish the player's health."},
      {label: "Stab City", position: [3715.853659, 63.947876], spawn: [37.71, 3671.21, 39.54, 226.47], type: "general", img: "assets/img/locations/stab_city.png", information: "Located just off Calafia Road, Stab City is a poverty-stricken trailer park, located on the western coast of the Alamo Sea at the source of the Zancudo River.<br><br>The settlement consists of numerous run-down trailers with a dirt road circling the entire trailer park. Being within close proximity of the Grand Senora Desert, Stab City is a hot and dusty place, with coyotes roaming nearby."},
      {label: "Sandy Shores Airfield", position: [3267.682927, 1692.80888], spawn: [1758.99, 3308.64, 41.15, 250.08], type: "general", img: "assets/img/locations/ss_airfield.jpg", information: "Sandy Shores Airfield is a private airfield located on Panorama Drive, southwest of the namesake town of Sandy Shores, Blaine County in the middle of the Grand Senora Desert.<br><br>The airfield consists of three unnamed and unmarked runways: two large parallel runways that run east to west and a smaller runway that runs northeast to southwest."},
      {label: "The Diamond Casino & Resort", position: [45.121951, 958.313224], spawn: [952.95, 82.54, 80.77, 114.61], type: "general", img: "assets/img/locations/casino.png", information: "The Diamond Casino & Resort is a casino business and luxury resort that is situated on the site of the original Vinewood Casino (also known as Be Lucky: Los Santos).<br><br>It is comprised of the casino, the Master Penthouse, a hotel, a penthouse garage, and a parking garage."},
      {label: "Mission Row Police Department", position: [-890.853659, 427.42519], spawn: [458.33, -970.58, 30.71, 42.49], type: "police", img: "assets/img/locations/mrpd.png", information: "The police station is a modern three-story building, demarcated by Sinner Street, Vespucci Boulevard, Atlee Street and Little Bighorn Avenue in Mission Row, Downtown Los Santos."}
    ],

    // Arrays
    createdMarkers: [],

    // Player Data
    playerData: {}
  },
  methods: {
    clearMessage() {
      this.message = null;
    },

    UpdateLoading(data) {
      if (data.state) this.loadingState = data.state;
      if (data.setter != this.loading) this.loading = data.setter;
    },

    ProcessCharacters(data) {
      // this.characterIndex = -1;
      // this.registeredCharacters = null;
      
      data.characters.forEach(characterData => {
        characterData.age = this.GetAge(characterData.dob);
        characterData.cash = this.FormatMoney(characterData.cash);
        characterData.bank = this.FormatMoney(characterData.bank);
        characterData.phone = this.FormatNumber(characterData.phone);
      });

      this.registeredCharacters = data.characters;
      this.characterIndex = 0;
      this.selectedCharacter = this.registeredCharacters[this.characterIndex];
      this.showCharacters = true;
    },

    GetAge(dob) {
      const today = new Date();
      const birthDate = new Date(dob);
      let age = today.getFullYear() - birthDate.getFullYear();
      const m = today.getMonth() - birthDate.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
        age = age - 1;
      }
      return age;
    },

    FormatMoney(amount) {
      amount = amount.toString();
      var pattern = /(-?\d+)(\d{3})/;
      while (pattern.test(amount))
      amount = amount.replace(pattern, "$1,$2");
      return "$" + amount;
    },

    FormatNumber(number) {
      var cleaned = ('' + number).replace(/\D/g, '')
      var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/)
      if (match) {
        return `${match[1]}-${match[2]}-${match[3]}`;
      }
      return null
    },

    ChangeSelected(direction, index) {
      if (direction == "right") {
        // console.log(`${this.characterIndex} | ${this.characterIndex + 1} | ${this.availableSlots} | ${this.availableSlots - 1}`)
        if ((this.characterIndex + 1) > (this.availableSlots - 1)) {
          this.characterIndex = 0;
        } else {
          this.characterIndex = this.characterIndex + 1;
        }
      } else if (direction == "left") {
        // console.log(`${this.characterIndex} | ${this.characterIndex - 1} | ${this.availableSlots} | ${this.availableSlots - 1}`)
        if ((this.characterIndex - 1) < 0) {
          this.characterIndex = this.availableSlots - 1;
        } else {
          this.characterIndex = this.characterIndex - 1;
        }
      }

      for (let i = 0; i < this.availableSlots; i++) {
        // console.log(`${i} | ${this.characterIndex}`)
        if (i == this.characterIndex) {
          // console.log(`match found on ${i}`);
          const charData = this.registeredCharacters[i];
          const charExists = charData != undefined;
          if (charExists) {
            // console.log(`${charData.name} Exists!`)
            this.selectedCharacter = charData;
          } else {
            // console.log(`Index (${i}) not found!`);
            this.selectedCharacter = null;
          }
          break;
        }
      }

      this.Post("cycle_character", JSON.stringify({direction: direction}));
    },

    CreateCharacter() {
      const isFormComplete = this.$refs.creatorForm.validate();
      if (this.formError) this.formError = false;
      if (isFormComplete) {
        // console.log("Form Complete, create character!");
        this.Post("createCharacter", JSON.stringify({
          firstname: this.charName,
          lastname: this.charSurname,
          nationality: this.charNationality,
          backstory: this.charBackstory,
          birthdate: this.charDob,
          gender: this.isFemale
        }), (createdChar) => {
          // console.log(`Create Char | Callback Data - ${JSON.stringify(createdChar)}`);
          if (createdChar) {
            this.showCharacters = false;
            this.showCreator = false;
          }
        });
      } else {
        // console.log("issue with the form, show error!");
        this.formError = true;
      }
    },

    ResetForm() {
      this.$refs.creatorForm.reset();
    },

    StartCreating() {
      // console.log("create char!");

      if (this.isEmptySlot()) {
        if (!this.showCreator) this.showCreator = true;
        // console.log("in empty slot!");
      } else {
        // console.log("in full slot!");
      }
    },

    PlayCharacter() {
      if (Object.keys(this.selectedCharacter).length > 0) {
        this.Post("play_character", JSON.stringify(this.selectedCharacter), (callbackStatus) => {
          if (callbackStatus == "ok") {
            this.showCharacters = false;
          }
        });
      } else {
        console.log("no selected char found!");
      }
    },

    StartEditing() {
      const charObject = {
        cid: this.selectedCharacter.cid,
        firstname: this.selectedCharacter.firstname,
        lastname: this.selectedCharacter.lastname,
        nationality: this.selectedCharacter.nationality,
        backstory: this.selectedCharacter.backstory,
        dob: this.selectedCharacter.dob,
        gender: this.selectedCharacter.gender
      }

      this.newCharData = charObject;
      this.showEditor = true;
    },

    EditCharacter() {
      if (this.selectedCharacter.firstname != this.newCharData.firstname || this.selectedCharacter.lastname != this.newCharData.lastname || this.selectedCharacter.nationality != this.newCharData.nationality || this.selectedCharacter.backstory != this.newCharData.backstory || this.selectedCharacter.dob != this.newCharData.dob || this.selectedCharacter.gender != this.newCharData.gender) {
        // console.log("found differences")
        this.Post("edit_character", JSON.stringify(this.newCharData), (callbackStatus) => {
          // console.log(`edit char callback data | ${JSON.stringify(callbackStatus)}`);
          if (callbackStatus == "UPDATED") {
            this.showEditor = false;
            this.selectedCharacter.firstname = this.newCharData.firstname,
            this.selectedCharacter.lastname = this.newCharData.lastname,
            this.selectedCharacter.nationality = this.newCharData.nationality,
            this.selectedCharacter.backstory = this.newCharData.backstory,
            this.selectedCharacter.dob = this.newCharData.dob,
            this.selectedCharacter.gender = this.newCharData.gender
            // console.log(`new | ${JSON.stringify(this.selectedCharacter)}`);
          }
        });
      } else {
        // console.log("still the same char data");
      }
    },

    isEmptySlot() {
      for (let i = 0; i < this.availableSlots; i++) {
        if (i == this.characterIndex) {
          const charData = this.registeredCharacters[i];
          const charExists = charData != undefined;
          if (!charExists) {
            return true;
          } else {
            return false;
          }
          break;
        }
      }
    },

    ToggleDelete() {
      this.deleteCheck = true;
    },
    
    DeleteChar() {
      // console.log(`delete char | ${JSON.stringify(this.selectedCharacter)}`)
      if (Object.keys(this.selectedCharacter).length > 0) {
        const charIndex = this.registeredCharacters.findIndex(character => character.cid == this.selectedCharacter.cid);
        // console.log(`Index | ${charIndex}`)
        if (charIndex != -1) {
          // console.log("delete char post!");
          this.Post("delete_character", JSON.stringify(this.selectedCharacter));
        }
      } else {
        // console.log("No selected character!");
      }
    },
    
    formatDate (date) {
      if (!date) return null

      const [year, month, day] = date.split('-')
      return `${month}/${day}/${year}`
    },

    parseDate (date) {
      if (!date) return null

      const [month, day, year] = date.split('/')
      return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`
    },

    isEquivalent(a, b) {
      // Create arrays of property names
      var aProps = Object.getOwnPropertyNames(a);
      var bProps = Object.getOwnPropertyNames(b);
  
      // If number of properties is different,
      // objects are not equivalent
      if (aProps.length != bProps.length) {
          return false;
      }
  
      for (var i = 0; i < aProps.length; i++) {
          var propName = aProps[i];
  
          // If values of same property are not equal,
          // objects are not equivalent
          if (a[propName] !== b[propName]) {
              return false;
          }
      }
  
      // If we made it this far, objects
      // are considered equivalent
      return true;
    },

    SetupApartments(data) {
      if (data.apartments) this.defaultApartments = data.apartments;
    },

    DisplayApt(data) {
      if (data.displayApts) {
        this.defaultApartments = data.apartments;
        this.showApartments = data.displayApts;
      }
    },

    ToggleApt(location) {
      if (!(this.isEquivalent(this.selectedApartment, location))) { // Check if clicked location isn't the same as already selected location
        // console.log(`New Location: ${JSON.stringify(location)}`);
        this.selectedApartment = location;
        this.Post("toggleApartment", JSON.stringify(this.selectedApartment));
      }
    },

    SelectApt() {
      // console.log(`Set apt as (${JSON.stringify(this.selectedApartment)})`);
      this.Post("setApartment", JSON.stringify(this.selectedApartment), (callbackData) => {
        if (callbackData) {
          this.selectedApartment = {};
          this.showApartments = false;
        }
      });
    },

    Post(nui_address, data, callbackFunction) {
      $.post(`http://${this.resource}/${nui_address}`, data, callbackFunction);
    },

    ShowDisconnect() {
      this.disconnectOption = true;
    },

    Disconnect() {
      this.Post("disconnect", JSON.stringify(this.selectedApartment));
    },

    // Map Methods
    CustomIcon(icon) {
      return L.icon({
        iconUrl: `assets/blips/${icon}.png`,
        iconSize:     [20, 20],
        iconAnchor:   [20, 20], 
        popupAnchor:  [-10, -27]
      });
    },

    ToggleLocation(location) {
      const element = $("#Location-Container");
      // console.log("toggled location", JSON.stringify(location));
      this.selectedLocation = location;
      if (this.selectedLocation.img != undefined) {
        document.getElementById("locationImg").src = this.selectedLocation.img;
      } else {
        document.getElementById("locationImg").src = "assets/img/locations/none.png";
      }

      element.css("display", "block");
    },

    Setup(data) {
      if (this.markers != null) {
        // console.log("RUN ME!");
        $("#Location-Container").css("display", "none");
        this.RemoveApartments();
      }

      // console.log(`Setup Map: ${JSON.stringify(data)}`)
      
      this.playerData.lastLocation = data.lastLocation;
      this.playerData.job = data.job.name;

      this.markers = L.layerGroup().addTo(this.map);

      for (let i = 0; i < this.locations.length; i++) {
        if (this.locations[i].type != "general") {
          if (this.locations[i].type != this.playerData.job) {
            // console.log(`Remove ${this.locations[i].name}`)
            this.locations.splice(i, 1);
          } else {
            const marker = new L.marker([this.locations[i].position[0], this.locations[i].position[1]], {icon: redPoint}).on('click', () => {
              this.selectedItem = this.locations.findIndex(loc => loc.position[0] == this.locations[i].position[0] && loc.position[1] == this.locations[i].position[1]); // When clicking a marker on the map, set the selected index on the right side UI
              this.ToggleLocation(this.locations[i]); // Display the left side location info UI
            }).addTo(this.map);

            this.markers.addLayer(marker);
          }
        } else {
          const marker = new L.marker([this.locations[i].position[0], this.locations[i].position[1]], {icon: redPoint}).on('click', () => {
            this.selectedItem = this.locations.findIndex(loc => loc.position[0] == this.locations[i].position[0] && loc.position[1] == this.locations[i].position[1]); // When clicking a marker on the map, set the selected index on the right side UI
            this.ToggleLocation(this.locations[i]); // Display the left side location info UI
          }).addTo(this.map);

          this.markers.addLayer(marker);
        }
      }

      this.locations.forEach((location, index) => {
        // console.log(location.name)
        if (location.type != "general") {
          if (location.type != this.playerData.job) {
            this.locations.splice(index, 1);
          } else {
            const marker = new L.marker([location.position[0], location.position[1]], {icon: redPoint}).on('click', () => {
              this.selectedItem = this.locations.findIndex(loc => loc.position[0] == location.position[0] && loc.position[1] == location.position[1]); // When clicking a marker on the map, set the selected index on the right side UI
              this.ToggleLocation(location); // Display the left side location info UI
            }).addTo(this.map);

            this.markers.addLayer(marker);
          }
        } else {
          const marker = new L.marker([location.position[0], location.position[1]], {icon: redPoint}).on('click', () => {
            this.selectedItem = this.locations.findIndex(loc => loc.position[0] == location.position[0] && loc.position[1] == location.position[1]); // When clicking a marker on the map, set the selected index on the right side UI
            this.ToggleLocation(location); // Display the left side location info UI
          }).addTo(this.map);

          this.markers.addLayer(marker);
        }
      });

      if (data.apartment) {
        console.log("apt", JSON.stringify(data.apartment));
        this.locations.push({
          name: data.apartment.name,
          label: data.apartment.label,
          information: data.apartment.information,
          position: [data.apartment.position.x, data.apartment.position.y],
          spawn: [data.apartment.position.x, data.apartment.position.y, data.apartment.position.z, data.apartment.position.w],
          apartmentType: data.apartment.apartmentType,
          type: data.apartment.type,
          img: `assets/img/locations/${data.apartment.apartmentType}.png`
        });

        const marker = L.marker([data.apartment.position.x, data.apartment.position.y], {icon: bluePoint}).on("click", () => {
          this.selectedItem = this.locations.findIndex(loc => loc.position[0] == data.apartment.position.x && loc.position[1] == data.apartment.position.y); // When clicking a marker on the map, set the selected index on the right side UI
          this.ToggleLocation(this.locations[this.selectedItem]); // Display the left side location info UI
        }).addTo(this.map);

        this.markers.addLayer(marker);
      }
    },

    RemoveApartments() {
      this.markers.clearLayers();
      this.markers = null;

      this.locations.forEach((location, index) => {
        if (location.type == "apartment") {
          this.locations.splice(index, 1);
        }
      });
      
      this.selectedItem = null;
    },

    Show(data) {
      const element = $("#Spawner-Container");
      data.show ? element.css("display", "block") : element.css("display", "none");
      this.map.invalidateSize()
    },

    Spawn(type) {
      let spawnData;

      if (type == undefined) {
        spawnData = {
          type: "location",
          location: this.selectedLocation
        }

        console.log("spawn at location!");
      } else if (type == "apartment") {
        console.log("spawn at apartment!");
        const location = this.locations.find(location => location.type == type);
        spawnData = {
          type: "apartment",
          location: location
        }

      } else {
        console.log("spawn at last location!");
        spawnData = {
          type: "last_location"
        }
      }

      this.Post("spawn_player", JSON.stringify(spawnData), (callbackStatus) => {
        console.log(`Spawn callback data | ${JSON.stringify(callbackStatus)}`);
        if (callbackStatus == "SPAWNING") {
          this.Show(false);
        }
      });
    }
  },

  watch: {
    charDob (val) {
      this.dateFormatted = this.formatDate(this.charDob);
    }
  },

  mounted() {
    // Characters Events
    RegisterEvent("setLoadingState", this.UpdateLoading);
    RegisterEvent("sendCharacters", this.ProcessCharacters);
    RegisterEvent("setup_apartments", this.SetupApartments);
    RegisterEvent("display_apartments", this.DisplayApt);

    // Key Presses
    window.addEventListener("keydown", function(event) {
      // console.log(`Key Pressed: ${event.key} | ${event.keyCode}`);

      switch(event.key) {
        case "ArrowRight":
          // console.log("Arrow right key pressed!");
          if (Characters.showCharacters && !Characters.showCreator && !Characters.showEditor) Characters.ChangeSelected("right");
          break;
        case "ArrowLeft":
          // console.log("Arrow left key pressed!");
          if (Characters.showCharacters && !Characters.showCreator && !Characters.showEditor) Characters.ChangeSelected("left");
          break;
        case "Enter":
          console.log("Enter pressed!");
          if (Characters.showCharacters && !Characters.showCreator && !Characters.showEditor) Characters.StartCreating();
          break;
      }
    });

    // Map Data
    
    // Map Creation
    this.map = L.map('Spawner-Map', {
      crs: CUSTOM_CRS,
      minZoom: 2, // How far you can zoom out (lower the number, further out it is)
      maxZoom: 5,
      Zoom: 8,
      maxNativeZoom: 8,
      preferCanvas: true,
      layers: [this.sateliteStyle],
      center: [1800, 1200],
      zoom: 2, // How far you're zoomed in by default
    });

    this.layerController = L.control.layers({ "Satelite": this.sateliteStyle,"Atlas": this.atlasStyle}, this.groups).addTo(this.map);
    this.map.on("click", this.onMapClick);

    // Locations UI (RIGHT)
    const locationCard = document.getElementById("Locations");
    locationCard.addEventListener("click", () => {
      const newLocation = this.locations[this.selectedItem];
      // console.log(`CARD CLICKED! | ${JSON.stringify(newLocation)}`);
      this.ToggleLocation(this.locations[this.selectedItem]);
      // this.selectedLocation = this.locations[this.selectedItem];
    });

    // Map Events
    RegisterEvent("setup_map", this.Setup);
    RegisterEvent("show_map", this.Show);
  }
});