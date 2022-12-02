#include <SFML/Graphics.hpp>
#include <iostream>

#define NAN 987654321
#define INFINITE 10100
#define MINUS_INFINITE -10100
#define WIN_WIDTH 1000
#define WIN_HEIGHT 1000

inline void pause()
{
	while (!sf::Keyboard::isKeyPressed(sf::Keyboard::Space));
}

class Vertex
{
public:
	float x, y;

	Vertex() :
		x(NAN),
		y(NAN)
	{}

	Vertex(const float xCoord, const float yCoord) :
		x(xCoord),
		y(yCoord)
	{}

	inline static bool exists(const Vertex& v) { return v.x == NAN || v.y == NAN; }

	void draw(sf::RenderWindow& window, const char marker = 'a')
	{
		sf::Vertex v(sf::Vector2f(x, y), sf::Color(255, 215, 0, 255));
		window.draw(&v, 1, sf::Points);
		if (marker == 'c')
		{
			sf::CircleShape circle(4.0, 8);
			circle.setOrigin(sf::Vector2f(4.0, 4.0));
			circle.setFillColor(sf::Color(255, 215, 0, 100));
			circle.setOutlineColor(sf::Color(255, 215, 0, 255));
			circle.setOutlineThickness(1);
			circle.setPosition(v.position);
			window.draw(circle);
		}
	}

	static const Vertex NullVertex;
};
const Vertex Vertex::NullVertex(NAN, NAN);

void drawLine(const Vertex& v1, const Vertex& v2, sf::RenderWindow& window)
{
	sf::Vertex line[2];
	line[0].position = sf::Vector2f(v1.x, v1.y);
	line[1].position = sf::Vector2f(v2.x, v2.y);
	window.draw(line, 2, sf::Lines);
}

static inline bool operator==(const Vertex& lhs, const Vertex& rhs) { return lhs.x == rhs.x && lhs.y == rhs.y; }
static inline bool operator!=(const Vertex& lhs, const Vertex& rhs) { return lhs.x != rhs.x || lhs.y != rhs.y; }

class Equation
{
	bool isVertical = false;
	//float a, c;

public:
	float a, c;
	Equation(const Vertex& v1, const Vertex& v2)
	{
		//std::cout << v1.x << ", " << v1.y << "   " << v2.x << ", " << v2.y << '\n';
		if (v1.x == v2.x)
		{
			isVertical = true;
			c = v1.x;
		}
		else
		{
			a = (v2.y - v1.y) / (v2.x - v1.x);
			c = v1.y - a * v1.x;
		}
	}

	float getY(const float x) const { return isVertical ? INFINITE : a * x + c; }
	float getX(const float y) const { return isVertical ? c : (y - c) / a; }

	Vertex intersect(const Equation& other) const
	{
		std::cout << "a1=" << a << " c1=" << c << "   a2=" << other.a << " c2=" << other.c<<'\n';
		return a == other.a ? Vertex::NullVertex
			: Vertex((other.c - c) / (a - other.a), (c * other.a - other.c * a) / (a - other.a));
	}
	Vertex intersect(const Vertex& v1, const Vertex& v2) const
	{
		const Vertex temp = intersect(Equation(v1, v2));
		return (temp.x >= v1.x && temp.x <= v2.x) || (temp.x >= v2.x && temp.x <= v1.x) ? temp : Vertex::NullVertex;
	}

	void draw(sf::RenderWindow& window) const
	{
		sf::Vertex line[2];
		line[0].color = line[1].color = sf::Color(255, 255, 255, 100);
		for (float i = MINUS_INFINITE; i < INFINITE; i += 10)
		{
			line[0].position = sf::Vector2f(i, getY(i));
			line[1].position = sf::Vector2f(i + 5, getY(i + 5));
			window.draw(line, 2, sf::Lines);
		}
	}

	static Vertex toInfinite(const Vertex& first, const Vertex& second)
	{
		const Equation e(first, second);
		if (e.isVertical)
			return first.y <= second.y ? Vertex(first.x, INFINITE) : Vertex(first.x, MINUS_INFINITE);
		else
			return first.x <= second.x ? Vertex(INFINITE, e.getY(INFINITE)) : Vertex(MINUS_INFINITE, e.getY(MINUS_INFINITE));
	}
};

template <class T>
class CyclicVector
{
	std::vector<T> vector;

public:
	CyclicVector(const size_t expectedSize = 8)
	{
		vector.reserve(expectedSize);
	}

	inline size_t size() const { return vector.size(); }
	inline const T& back() const { return vector.back(); }
	inline const T& front() const { return vector.front(); }
	inline const std::vector<T>& getVector() const { return vector; }

	inline void push_back(const T& obj)
	{
		vector.push_back(obj);
	}
	inline void pop_back()
	{
		vector.pop_back();
	}
	inline void insert(const size_t index, const T& obj)
	{
		vector.insert(index, obj);
	}
	inline void erase(const size_t start, const size_t end)
	{
		vector.erase(vector.begin() + start, vector.end() + end);
	}
	inline void reserve(const size_t size)
	{
		vector.reserve(size);
	}

	T& operator[](const long idx) { return vector[mapIndex(idx)]; }
	const T& operator[](const long idx) const { return vector[mapIndex(idx)]; }

	inline size_t mapIndex(const long idx) const { return idx >= 0 ? idx % vector.size() : idx + (vector.size() * (-idx / vector.size() + 1)); }
};

class Kernel
{
	CyclicVector<Vertex> vertices;
	size_t F = NAN, L = NAN;

public:
	Kernel()
	{}

	Kernel(const Vertex& v1, const Vertex& v2, const Vertex& v3, const size_t expectedSize = 8) :
		L(0),
		F(2)
	{
		vertices.reserve(expectedSize);
		vertices.push_back(v1);
		vertices.push_back(v2);
		vertices.push_back(v3);
	}

	Kernel(const CyclicVector<Vertex>& vertexVector) :
		vertices(vertexVector)
	{}

	inline const size_t size() const { return vertices.size(); }
	inline const Vertex& getF() const { return vertices[F]; }
	inline const Vertex& getL() const { return vertices[L]; }
	inline const size_t indexOfF() const { return F; }
	inline const size_t indexOfL() const { return L; }

	void addVertex(const Vertex& vertex)
	{
		vertices.push_back(vertex);
	}
	void replaceVertex(const size_t index, const Vertex& vertex)
	{
		vertices[index] = vertex;
	}

	void draw(sf::RenderWindow& window) const 
	{
		if (vertices.size() == 0)
			return;

		if (vertices.size() == 1)
		{
			sf::Vertex point(sf::Vector2f(vertices[0].x, vertices[0].y), sf::Color(255, 128, 0, 255));
			window.draw(&point, 1, sf::Points);
			return;
		}

		sf::Vertex vert[3];
		vert[0].color = vert[1].color = sf::Color(178, 102, 255, 255);
		for (size_t i = 0; i < vertices.size() - 1; ++i)
		{
			vert[0].position = sf::Vector2f(vertices[i].x, vertices[i].y);
			vert[1].position = sf::Vector2f(vertices[i + 1].x, vertices[i + 1].y);
			window.draw(vert, 2, sf::Lines);
		}
		vert[0].position = sf::Vector2f(vertices[0].x, vertices[0].y);
		vert[1].position = sf::Vector2f(vertices.back().x, vertices.back().y);
		window.draw(vert, 2, sf::Lines);

		if (vertices.size() >= 3)
		{
			vert[0].color = vert[1].color = vert[2].color = sf::Color(172, 102, 255, 80);
			vert[0].position = sf::Vector2f(vertices[0].x, vertices[0].y);
			for (size_t i = 1; i < vertices.size() - 1; ++i)
			{
				vert[1].position = sf::Vector2f(vertices[i].x, vertices[i].y);
				vert[2].position = sf::Vector2f(vertices[i + 1].x, vertices[i + 1].y);
				window.draw(vert, 3, sf::Triangles);
			}
		}

		/*sf::Text text("F", FONT, 16);
		if (F != NAN)
		{
			text.setPosition(sf::Vector2f(vertices[F].x, vertices[F].y - 20));
			window.draw(text);
		}
		if (L != NAN)
		{
			text.setString("L");
			text.setPosition(sf::Vector2f(vertices[L].x, vertices[L].y - 20));
			window.draw(text);
		}*/
	}

	Vertex& operator[](const long idx) { return vertices[idx]; }
	const Vertex& operator[](const long idx) const { return vertices[idx]; }

	inline size_t mapIndex(const long idx) const { return vertices.mapIndex(idx); }

	static const Kernel NullKernel;
};
const Kernel Kernel::NullKernel;

class Polygon
{
	bool isNormalized = true;
	CyclicVector<Vertex> vertices;

	bool isClockwise() const
	{
		float area = 0.0;
		if (vertices.size() > 2)
		{
			for (size_t i = 0; i < vertices.size() - 1; ++i)
				area += -vertices[i].y * vertices[i + 1].x + vertices[i].x * vertices[i + 1].y;
			area += -vertices.back().y * vertices.front().x + vertices.back().x * vertices.front().y;
		}
		return area >= 0;
	}

	size_t findReflexVertex() const
	{
		if (isReflex(vertices.back(), vertices.front(), vertices[1]))
			return 0;

		for (size_t i = 0; i < vertices.size() - 2; ++i)
			if (isReflex(vertices[i], vertices[i + 1], vertices[i + 2]))
				return i + 1;

		if (isReflex(vertices[vertices.size() - 2], vertices.back(), vertices.front()))
			return vertices.size() - 1;

		return vertices.size();
	}

	void normalize()
	{
		if (isNormalized)
			return;
		if (isClockwise())
		{
			for (size_t i = 0; i < vertices.size() / 2; ++i)
				std::swap(vertices[i], vertices[vertices.size() - i - 1]);
		}
		isNormalized = true;
	}

public:
	void addVertex(const Vertex& vertex) 
	{ 
		vertices.push_back(vertex);
		isNormalized = false;
	}

	void popVertex()
	{
		if (vertices.size() == 0) return;
		vertices.pop_back();
		isNormalized = false;
	}

	Kernel getKernel(sf::RenderWindow& window)
	{
		if (vertices.size() < 3)
			return Kernel::NullKernel;
		if (vertices.size() == 3)
			return Kernel(vertices[0], vertices[1], vertices[2], 3);

		normalize();

		const size_t first = findReflexVertex();
		if (first == vertices.size()) // polygon is convex
			return Kernel(vertices);

		// - Lee & Preparata -
		Kernel K(
			Equation::toInfinite(vertices[first - 1], vertices[first]),
			vertices[first],
			Equation::toInfinite(vertices[first + 1], vertices[first])
		);
		//std::cout << "F: " << K.getF().x << ", " << K.getF().y<<'\n';
		//std::cout << "L: " << K.getL().x << ", " << K.getL().y << '\n';
		for (size_t i = first + 1; vertices.mapIndex(i) != first; ++i)
		{
			Equation E(vertices[i], vertices[i + 1]);
			if (isReflex(vertices[i - 1], vertices[i], vertices[i + 1]))
			{
				std::cout << crossProduct(vertices[i], vertices[i + 1], K.getF()) << '\n';
				if (crossProduct(vertices[i], vertices[i + 1], K.getF()) <= 0) // on or to the right
				{
				//	Vertex W1, W2;
				//	std::cout << K.indexOfF() << " L:" << K.indexOfL() << '\n';
				//	for (size_t i = K.indexOfF(); K.mapIndex(i) != K.indexOfL(); ++i) // CCW from F until L
				//	{
				//		//std::cout << "Ki(" << K[i].x << ", " << K[i].y << ") Ki+1(" << K[i + 1].x << ", " << K[i + 1].y << '\n';
				//		drawLine(K[i], K[i + 1], window);
				//		window.display();
				//		W1 = E.intersect(K[i], K[i + 1]);
				//		if (W1 != Vertex::NullVertex)
				//		{
				//			K[i + 1] = W1;
				//			break;
				//		}
				//	}
				//	if (W1 == Vertex::NullVertex)
				//		return Kernel::NullKernel;
				//	W1.draw(window, 'c');

				//	for (size_t i = K.indexOfF(); i > 0; --i) // CW from F until head
				//	{
				//		W2 = E.intersect(K[i], K[i - 1]);
				//		if (W2 != Vertex::NullVertex)
				//		{
				//			//K[i] = W2;
				//			break;
				//		}
				//	}
				//	W2.draw(window, 'c');
				//	window.display();
				}
			}
			else
			{
				Equation E(vertices[i], vertices[i + 1]);
				E.draw(window);
				window.display();
				pause();
				if (crossProduct(vertices[i], vertices[i + 1], K.getF()) <= 0) // on or to the right
				{
					Vertex W1, W2;
					for (size_t i = K.size(); i > 0; --i)
					{
						W1 = E.intersect(K[i], K[i - 1]);
						if (W1 != Vertex::NullVertex)
						{
							//K[i] = W1;
							break;
						}
					}

					//for (size_t i = K.indexOfL(); K.mapIndex(i) != K.indexOfF(); --i) // CW from L until F
					//{
					//	W1 = E.intersect(K[i], K[i - 1]);
					//	if (W1 != Vertex::NullVertex)
					//	{
					//		//K[i] = W1;
					//		break;
					//	}
					//}

					for (size_t i = K.indexOfL(); i < K.size(); ++i) // CCW from L until tail
					{
						W2 = E.intersect(K[i], K[i + 1]);
						if (W2 != Vertex::NullVertex)
						{
							//K[i + 1] = W2;
							break;
						}
					}
					std::cout << "W1(" << W1.x << ", " << W1.y<<") W2(" << W2.x << ", " << W2.y << ")\n";
					W1.draw(window, 'c');
					W2.draw(window, 'c');
					K.draw(window);
					window.display();
					//pause();
				}
				break;
			}
		}
		return K;
	}

	void draw(sf::RenderWindow& window) const 
		{
			if (vertices.size() == 0)
				return;

			sf::CircleShape circle(4.0, 8);
			circle.setOrigin(sf::Vector2f(4.0, 4.0));
			circle.setFillColor(sf::Color(0, 250, 150, 100));
			circle.setOutlineColor(sf::Color(0, 250, 150, 255));
			circle.setOutlineThickness(1);

			if (vertices.size() == 1)
			{
				sf::Vertex point(sf::Vector2f(vertices[0].x, vertices[0].y), sf::Color(0, 250, 150, 255));
				window.draw(&point, 1, sf::Points);
				circle.setPosition(point.position);
				window.draw(circle);
				return;
			}

			sf::Vertex line[2];
			line[0].color = line[1].color = sf::Color(0, 250, 150, 255);
			for (size_t i = 0; i < vertices.size() - 1; ++i)
			{
				line[0].position = sf::Vector2f(vertices[i].x, vertices[i].y);
				line[1].position = sf::Vector2f(vertices[i + 1].x, vertices[i + 1].y);
				window.draw(line, 2, sf::Lines);
				circle.setPosition(line[0].position);
				window.draw(circle);
			}
			line[0].position = sf::Vector2f(vertices[0].x, vertices[0].y);
			line[1].position = sf::Vector2f(vertices.back().x, vertices.back().y);
			window.draw(line, 2, sf::Lines);
			circle.setPosition(line[1].position);
			window.draw(circle);
		}

	inline static float crossProduct(const Vertex& v1, const Vertex& v2, const Vertex& v3)
	{
		return ((v2.x - v1.x) * (v3.y - v2.y) - (v3.x - v2.x) * (v2.y - v1.y));
	}
	inline static bool isReflex(const Vertex& v1, const Vertex& v2, const Vertex& v3)
	{
		return crossProduct(v1, v2, v3) > 0;
	}
};

int main()
{
	sf::RenderWindow window(sf::VideoMode(WIN_WIDTH, WIN_HEIGHT), "Kernel of a polygon");
	window.setFramerateLimit(60);

	Polygon inputPoly;
	Kernel kernel;
	Vertex(6, 13).draw(window);
	Vertex(9, 12).draw(window);
	Equation eq(Vertex(6, 13), Vertex(9, 12));
	eq.draw(window);
	Vertex t = eq.intersect(Vertex(1, 3), Vertex(-5, -2));
	std::cout << t.x <<"  "<<t.y<<'\n';

	while (window.isOpen())
	{
		sf::Event event;
		while (window.pollEvent(event))
		{
			if (event.type == sf::Event::Closed)
				window.close();
			else if (event.type == sf::Event::MouseButtonReleased)
			{
				const sf::Vector2i mPos = sf::Mouse::getPosition(window);
				inputPoly.addVertex(Vertex(mPos.x, mPos.y));
				window.clear();
				kernel = inputPoly.getKernel(window);
			}
		}

		//window.clear();
		inputPoly.draw(window);
		//kernel.draw(window);;
		window.display();
	}

	return 0;
}








//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//#include <SFML/Graphics.hpp>
//#include <vector>
//#include <iostream>
//
//#define W_WIDTH 800
//#define W_HEIGHT 800
//
//class Vertex
//{
//public:
//	bool isReflex = false;
//	sf::Vector2f position;
//
//	Vertex(const sf::Vector2f& position) :
//		position(position)
//	{}
//
//	inline void setReflex(const sf::Vector2f& before, const sf::Vector2f& after, const bool reverse)
//	{
//		if(reverse)
//			isReflex = ((position.x - after.x) * (before.y - position.y) - (before.x - position.x) * (position.y - after.y)) > 0;
//		else
//			isReflex = ((position.x - before.x) * (after.y - position.y) - (after.x - position.x) * (position.y - before.y)) > 0;
//	}
//};
//
//class Equation
//{
//	const float b = 1.0;
//	float a, c;
//
//public:
//	Equation(const Vertex& v1, const Vertex& v2)
//	{
//		a = (v2.position.y - v1.position.y) / (v2.position.x - v1.position.x);
//		c = v1.position.y - a * v1.position.x;
//	}
//
//	float getY(const float x) {	return a * x + c; }
//	float getX(const float y) { return (y - c) / a; }
//};
//
//class OneEndedSegment
//{
//	float xStart, xOpposite;
//	Equation eq;
//	sf::Color color;
//
//public:
//	OneEndedSegment(const Vertex& v1, const Vertex& v2, const sf::Color& col = sf::Color::White) :
//		eq(v1, v2),
//		xStart(v1.position.x),
//		xOpposite(v2.position.x),
//		color(col)
//	{}
//
//	void draw(sf::RenderWindow& window)
//	{
//		sf::Vertex l[2];
//		l[0].color = color;
//		l[1].color = color;
//
//		if (xStart < xOpposite)
//		{
//			l[0].position = sf::Vector2f(xStart, eq.getY(xStart));
//			l[1].position = sf::Vector2f(0, eq.getY(0));
//		}
//		else
//		{
//			l[0].position = sf::Vector2f(xStart, eq.getY(xStart));
//			l[1].position = sf::Vector2f(W_WIDTH, eq.getY(W_WIDTH));
//		}
//		window.draw(l, 2, sf::Lines);
//	}
//};
//
//
//class UnboundedPolygon
//{
//	std::vector<Vertex> vertices;
//
//public:
//	void addVertex(const sf::Vector2f& vertex)
//	{
//		vertices.push_back(vertex);
//	}
//
//	void popVertex()
//	{
//		if (vertices.size())
//			vertices.pop_back();
//	}
//
//
//
//	void draw(sf::RenderWindow& window)
//	{
//		if (vertices.size() == 0)
//			return;
//
//		if (vertices.size() == 1)
//		{
//			sf::Vertex point(vertices[0].position, sf::Color::Green);
//			window.draw(&point, 1, sf::Points);
//			return;
//		}
//
//		sf::Vertex line[2];
//		line[0].color = sf::Color::Green;
//		line[1].color = sf::Color::Green;
//		for (size_t i = 0; i < vertices.size() - 1; ++i)
//		{
//			line[0].position = vertices[i].position;
//			line[1].position = vertices[i + 1].position;
//			window.draw(line, 2, sf::Lines);
//		}
//
//		OneEndedSegment seg1(vertices[0], vertices[1]), seg2(vertices.back(), vertices[vertices.size() - 2]);
//		seg1.draw(window);
//		seg2.draw(window);
//	}
//};
//
//class Polygon
//{
//	std::vector<Vertex> vertices;
//
//	void findReflex()
//	{
//		if (vertices.size() > 2)
//		{
//			const bool direction = isClockwise();
//			for (size_t i = 1; i < vertices.size() - 1; ++i)
//				vertices[i].setReflex(vertices[i - 1].position, vertices[i + 1].position, direction);
//			vertices.front().setReflex(vertices.back().position, vertices[1].position, direction);
//			vertices.back().setReflex(vertices[vertices.size() - 2].position, vertices.front().position, direction);
//		}
//	}
//
//	bool isClockwise()
//	{
//		float area = 0.0;
//		if (vertices.size() > 2)
//		{
//			for (size_t i = 0; i < vertices.size() - 1; ++i)
//				area += -vertices[i].position.y * vertices[i + 1].position.x + vertices[i].position.x * vertices[i + 1].position.y;
//			area += -vertices.back().position.y * vertices.front().position.x + vertices.back().position.x * vertices.front().position.y;
//		}
//		return area >= 0;
//	}
//
//public:
//	void addVertex(const sf::Vector2f& vertex) 
//	{ 
//		vertices.push_back(vertex);
//		findReflex();
//	}
//
//	void popVertex()
//	{
//		if (vertices.size() == 0) return;
//		vertices.pop_back();
//		findReflex();
//	}
//
//	void findWedges()
//	{
//		for (size_t i = 1; i < vertices.size() - 1; ++i)
//			if (vertices[i].isReflex)
//			{
//
//			}
//	}
//
//	void draw(sf::RenderWindow& window)
//	{
//		if (vertices.size() == 0)
//			return;
//
//		sf::CircleShape circle(4.0, 8);
//		circle.setOrigin(sf::Vector2f(4.0, 4.0));
//		circle.setFillColor(sf::Color(255, 255, 255, 100));
//		circle.setOutlineColor(sf::Color(255, 255, 255, 255));
//		circle.setOutlineThickness(1);
//
//		if (vertices.size() == 1)
//		{
//			sf::Vertex point(vertices[0].position);
//			window.draw(&point, 1, sf::Points);
//			circle.setPosition(vertices[0].position);
//			window.draw(circle);
//			return;
//		}
//
//		sf::Vertex line[2];
//		for(size_t i = 0; i < vertices.size() - 1; ++i)
//		{
//			line[0].position = vertices[i].position;
//			line[1].position = vertices[i + 1].position;
//			window.draw(line, 2, sf::Lines);
//			if (vertices[i].isReflex)
//				circle.setFillColor(sf::Color::Red);
//			else
//				circle.setFillColor(sf::Color(255, 255, 255, 100));
//			circle.setPosition(vertices[i].position);
//			window.draw(circle);
//		}
//		line[0].position = vertices.front().position;
//		line[1].position = vertices.back().position;
//		window.draw(line, 2, sf::Lines);
//		circle.setPosition(vertices.back().position);
//		if (vertices.back().isReflex)
//			circle.setFillColor(sf::Color::Red);
//		else
//			circle.setFillColor(sf::Color(255, 255, 255, 100));
//		window.draw(circle);
//	}
//};
//
//int main()
//{
//	sf::RenderWindow window(sf::VideoMode(800, 800), "SFML works!");
//	window.setFramerateLimit(160);
//	UnboundedPolygon p;
//
//
//	while (window.isOpen())
//	{
//		sf::Event event;
//		while (window.pollEvent(event))
//		{
//			if (event.type == sf::Event::Closed)
//				window.close();
//			//else if (event.type == sf::Event::MouseMoved)
//			//{
//			//	p.popVertex();
//			//	p.addVertex(static_cast<sf::Vector2f>(sf::Mouse::getPosition(window)));
//			//}
//			else if (event.type == sf::Event::MouseButtonReleased)
//				p.addVertex(static_cast<sf::Vector2f>(sf::Mouse::getPosition(window)));
//		}
//
//		window.clear();
//		p.draw(window);
//		window.display();
//	}
//
//	return 0;
//}
