-- Active: 1669653924357@@127.0.0.1@5432@postgres

--creating train table
CREATE TABLE train 
( 
train_no INT NOT NULL,--train number
doj date NOT NULL,--date of journey
ac_coaches_av INT,--number of available ac coaches
sl_coaches_av INT,--number of available ac coaches
total_ac_seat INT,--total number of ac seats
total_sl_seat INT,--total number of sl seats
av_ac_seats INT,--ac seats available after each booking
av_sl_seats INT--sl seats available after each booking
);

--creating tickets table
CREATE TABLE tickets
(
pnr_no INT not null,
train_no INT,
doj date,
no_of_passengers INT,
name_of_passenger TEXT[],
first_birth_number INT, --first berth number
last_birth_number INT, --last berth number
berth_type char(2),
first_seat_coach_number INT, --first seat assigned coach number
last_seat_coach_number INT --last seat assigned coach number
);


CREATE OR REPLACE FUNCTION add_train(train_number INT, date_of_journey DATE,sl_coach INT,ac_coach INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  total_ac_seats INT;
  total_sl_seats INT;
BEGIN 
 --ac_coach = select av_ac_seats  from train where train_no = train_number;
  total_ac_seats := ac_coach*18;
  total_sl_seats := sl_coach*24;
  INSERT INTO train(train_no,doj,ac_coaches_av,sl_coaches_av,total_ac_seat,total_sl_seat,av_ac_seats,av_sl_seats)
  VALUES (train_number,date_of_journey,ac_coach,sl_coach,total_ac_seats,total_sl_seats,total_ac_seats,total_sl_seats);
  return train_number;
END;
$$;


CREATE OR REPLACE FUNCTION book_tickets(train_number INT,date_of_journey DATE,n INT,names TEXT[],berth_type VARCHAR)
RETURNS TEXT as $$
DECLARE
  av_seats INT;
  ac_seats INT;
  sl_seats INT;
  output TEXT;
  first_seat_number INT;
  last_seat_number INT;
  first_seat_coach_number INT;
  last_seat_coach_number INT;
  train_availability record;
  pnr_number INT := floor(random() * 10000000 + 11)::int;
BEGIN
  execute format('select * from train where train.train_no=%L and train.doj=%L', train_number, date_of_journey)
	into train_availability;
  if train_availability is NULL then
 		output = 'Train not available';
		return output;
 	end if;

  if berth_type='S' then
    execute format('SELECT total_sl_seat FROM train WHERE train_no=%L AND doj=%L', train_number, date_of_journey)
		INTO sl_seats;
    execute format('SELECT av_sl_seats FROM train WHERE train_no=%L AND doj=%L', train_number, date_of_journey)
		INTO av_seats;
	else
    execute format('SELECT total_ac_seat FROM train WHERE train_no=%L AND doj=%L', train_number, date_of_journey)
		INTO ac_seats;
    execute format('SELECT av_ac_seats FROM train WHERE train_no=%L AND doj=%L', train_number, date_of_journey)
		INTO av_seats;
	end if;
  if av_seats < n 
  then
    output = 'Seats not available';	
    return output;
  end if;

  if berth_type='S' THEN
    first_seat_number = (sl_seats-av_seats)%18+1;
    last_seat_number= (sl_seats-av_seats+n-1)%18+1;
    first_seat_coach_number=(sl_seats-av_seats)/18+1;
    last_seat_coach_number=(sl_seats-av_seats+n-1)/18+1;
    INSERT INTO tickets(pnr_no,train_no,doj,no_of_passengers,name_of_passenger,first_birth_number,last_birth_number,berth_type,first_seat_coach_number,last_seat_coach_number)
    VALUES ( pnr_number,train_number,date_of_journey,n,names,first_seat_number,last_seat_number,'SL',first_seat_coach_number,last_seat_coach_number);

output = pnr_number|| ' ' ||train_number|| ' ' || date_of_journey || ' ' || n || ' ' || names || ' ' || first_seat_number || ' ' ||  last_seat_number || ' ' ||  'SL' || ' ' || first_seat_coach_number || ' ' || last_seat _coach_number;

  ELSE
   first_seat_number = (ac_seats-av_seats)%18+1;
    last_seat_number= (ac_seats-av_seats+n-1)%18+1;
    first_seat_coach_number=(ac_seats-av_seats)/18+1;
    last_seat_coach_number=(ac_seats-av_seats+n-1)/18+1;
    INSERT INTO tickets(pnr_no,train_no,doj,no_of_passengers,name_of_passenger,first_birth_number,last_birth_number,berth_type,first_seat_coach_number,last_seat_coach_number)
    VALUES ( pnr_number,train_number,date_of_journey,n,names,first_seat_number,last_seat_number,'AC',first_seat_coach_number,last_seat_coach_number);
output = pnr_number|| ' ' ||train_number|| ' ' || date_of_journey || ' ' || n || ' ' || names || ' ' || first_seat_number || ' ' ||  last_seat_number || ' ' ||  'SL' || ' ' || first_seat_coach_number || ' ' || last_seat _coach_number;
  end if;
 

  if berth_type='S' THEN
    UPDATE train
    SET av_sl_seats=av_seats-n
    WHERE train_no=train_number AND doj=date_of_journey;
  else
    UPDATE train
    SET av_ac_seats=av_seats-n
    WHERE train_no=train_number AND doj=date_of_journey;
  end if;
  return output;
END;
$$
LANGUAGE plpgsql;



SELECT book_tickets(1::INTEGER,'2020-11-12'::DATE,26::INTEGER,'{a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}'::TEXT[],'A'::CHAR);
SELECT book_tickets(2::INTEGER,'2020-11-12'::DATE,26::INTEGER,'{a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}'::TEXT[],'S'::CHAR);
Select add_train(001,'2020-11-12',10,10);
Select add_train(02,'2020-11-12',10,10);
Select add_train(003,'2020-11-12',3,4);
Select add_train(004,'2020-11-12',2,5);
Select add_train(006,'2020-11-12',10,12);
SELECT * FROM train LIMIT 100;


